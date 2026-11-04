import asyncio
import json
import re
import socket
import subprocess
from pathlib import Path
from setup_sip import setup_sip_inbound

IVR_SIGNAL_FILE = Path(__file__).parent / "ivr_signal.json"


def check_sip_info_dtmf(data: bytes) -> None:
    if not data.startswith(b"INFO "):
        return
    try:
        text = data.decode(errors="ignore")
        m = re.search(r"Signal\s*=\s*([123])", text, re.IGNORECASE)
        if m:
            digit = m.group(1)
            IVR_SIGNAL_FILE.write_text(json.dumps({"digit": digit}), encoding="utf-8")
            print(f"[Bridge SIP DTMF] Detected keypad press: {digit}", flush=True)
    except Exception:
        pass


def get_lan_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def get_wsl_ip() -> str:
    out = subprocess.check_output(["wsl", "-e", "hostname", "-I"], text=True).strip()
    return out.split()[0]


def ensure_sip_and_livekit_ips(lan_ip: str, wsl_ip: str) -> None:
    livekit_yaml = Path(__file__).parent / "livekit.yaml"
    if livekit_yaml.exists():
        content = livekit_yaml.read_text(encoding="utf-8")
        lines = []
        changed = False
        for line in content.splitlines():
            if line.strip().startswith("node_ip:"):
                expected = f"  node_ip: {wsl_ip}"
                if line != expected:
                    changed = True
                lines.append(expected)
            else:
                lines.append(line)
        if changed:
            livekit_yaml.write_text("\n".join(lines) + "\n", encoding="utf-8")
            subprocess.run(["wsl", "-u", "root", "-e", "docker", "restart", "livekit-server"], check=False)

    try:
        env_out = subprocess.check_output(
            [
                "wsl", "-u", "root", "-e", "docker", "inspect", "livekit-sip",
                "--format", "{{.State.Running}} | {{json .Config.Env}}",
            ],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        env_out = ""

    if not env_out.startswith("true |") or f"nat_1_to_1_ip: {lan_ip}" not in env_out:
        print(f"[Bridge] Starting livekit-sip container for Wi-Fi IP: {lan_ip}", flush=True)
        sip_cfg = (
            "api_key: devkey\n"
            "api_secret: secret\n"
            "ws_url: ws://livekit:7880\n"
            "redis:\n"
            "  address: redis:6379\n"
            "sip_port: 5060\n"
            "rtp_port: 10000-10020\n"
            "use_external_ip: false\n"
            f"nat_1_to_1_ip: {lan_ip}\n"
            "logging:\n"
            "  level: debug\n"
        )
        subprocess.run(["wsl", "-u", "root", "-e", "docker", "rm", "-f", "livekit-sip"], check=False)
        cmd = [
            "wsl", "-u", "root", "-e", "docker", "run", "-d",
            "--name", "livekit-sip",
            "--restart", "unless-stopped",
            "--network", "ai-call-assistant_default",
            "-p", "5060:5060/udp",
            "-p", "5060:5060/tcp",
            "-p", "10000-10020:10000-10020/udp",
            "-e", f"SIP_CONFIG_BODY={sip_cfg}",
            "livekit/sip:latest",
        ]
        subprocess.run(cmd, check=False)


class PerClientWSLProtocol(asyncio.DatagramProtocol):
    def __init__(self, parent: "UDPBridgeProtocol", client_addr: tuple[str, int]):
        self.parent = parent
        self.client_addr = client_addr
        self.transport = None

    def connection_made(self, transport):
        self.transport = transport
        sock = transport.get_extra_info("socket")
        if sock:
            try:
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)
            except Exception:
                pass

    def datagram_received(self, data: bytes, addr: tuple[str, int]):
        if self.parent.lan_transport:
            self.parent.lan_transport.sendto(data, self.client_addr)


class UDPBridgeProtocol(asyncio.DatagramProtocol):
    def __init__(self, wsl_ip: str, port: int):
        self.wsl_ip = wsl_ip
        self.port = port
        self.lan_transport = None
        self.client_transports: dict[tuple[str, int], asyncio.DatagramTransport] = {}
        self.pending_packets: dict[tuple[str, int], list[bytes]] = {}

    def connection_made(self, transport):
        self.lan_transport = transport
        sock = transport.get_extra_info("socket")
        if sock:
            try:
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 1048576)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, 1048576)
            except Exception:
                pass

    async def _get_or_create_client_transport(self, client_addr: tuple[str, int]):
        loop = asyncio.get_running_loop()
        transport, _ = await loop.create_datagram_endpoint(
            lambda: PerClientWSLProtocol(self, client_addr),
            remote_addr=(self.wsl_ip, self.port),
        )
        self.client_transports[client_addr] = transport
        for pkt in self.pending_packets.pop(client_addr, []):
            transport.sendto(pkt)

    def datagram_received(self, data: bytes, addr: tuple[str, int]):
        if self.port == 5060:
            check_sip_info_dtmf(data)
        if self.port == 5060 and data.startswith(b"REGISTER "):
            text = data.decode(errors="ignore")
            lines = text.split("\r\n")
            resp_headers = ["SIP/2.0 200 OK"]
            for h in lines[1:]:
                if h.lower().startswith(("via:", "from:", "to:", "call-id:", "cseq:", "contact:")):
                    if h.lower().startswith("to:") and ";tag=" not in h.lower():
                        h = h + ";tag=lkbridge123"
                    resp_headers.append(h)
            resp_headers.append("Expires: 3600")
            resp_headers.append("Content-Length: 0")
            resp = "\r\n".join(resp_headers) + "\r\n\r\n"
            if self.lan_transport:
                self.lan_transport.sendto(resp.encode("utf-8"), addr)
            return

        t = self.client_transports.get(addr)
        if t is not None:
            t.sendto(data)
        else:
            if addr not in self.pending_packets:
                self.pending_packets[addr] = [data]
                asyncio.create_task(self._get_or_create_client_transport(addr))
            else:
                self.pending_packets[addr].append(data)


async def handle_tcp(reader: asyncio.StreamReader, writer: asyncio.StreamWriter, wsl_ip: str, port: int):
    try:
        wsl_reader, wsl_writer = await asyncio.open_connection(wsl_ip, port)
    except Exception:
        writer.close()
        return

    async def pipe_client_to_wsl(r: asyncio.StreamReader, w: asyncio.StreamWriter):
        try:
            while data := await r.read(8192):
                if port == 5060:
                    check_sip_info_dtmf(data)
                if port == 5060 and data.startswith(b"REGISTER "):
                    text = data.decode(errors="ignore")
                    lines = text.split("\r\n")
                    resp_headers = ["SIP/2.0 200 OK"]
                    for h in lines[1:]:
                        if h.lower().startswith(("via:", "from:", "to:", "call-id:", "cseq:", "contact:")):
                            if h.lower().startswith("to:") and ";tag=" not in h.lower():
                                h = h + ";tag=lkbridge123"
                            resp_headers.append(h)
                    resp_headers.append("Expires: 3600")
                    resp_headers.append("Content-Length: 0")
                    resp = "\r\n".join(resp_headers) + "\r\n\r\n"
                    writer.write(resp.encode("utf-8"))
                    await writer.drain()
                    continue
                w.write(data)
                await w.drain()
        except Exception:
            pass
        finally:
            w.close()

    async def pipe_wsl_to_client(r: asyncio.StreamReader, w: asyncio.StreamWriter):
        try:
            while data := await r.read(8192):
                w.write(data)
                await w.drain()
        except Exception:
            pass
        finally:
            w.close()

    await asyncio.gather(pipe_client_to_wsl(reader, wsl_writer), pipe_wsl_to_client(wsl_reader, writer))


async def keep_wsl_alive():
    proc = await asyncio.create_subprocess_exec(
        "wsl", "-u", "root", "-e", "bash", "-c", "service docker start && sleep infinity"
    )
    await proc.wait()


async def main():
    asyncio.create_task(keep_wsl_alive())
    await asyncio.sleep(2)
    lan_ip = get_lan_ip()
    wsl_ip = get_wsl_ip()
    ensure_sip_and_livekit_ips(lan_ip, wsl_ip)
    print(f"[Bridge] Auto-Detected Wi-Fi IP: {lan_ip} -> WSL2 ({wsl_ip})", flush=True)
    print(f"[Bridge] Linphone Domain / Server IP to use on phone: {lan_ip}:5060", flush=True)
    loop = asyncio.get_running_loop()

    udp_ports = [5060] + list(range(10000, 10021))
    for port in udp_ports:
        try:
            await loop.create_datagram_endpoint(
                lambda p=port: UDPBridgeProtocol(wsl_ip, p),
                local_addr=(lan_ip, port),
            )
        except Exception as e:
            print(f"[Bridge] Warning binding UDP {port}: {e}", flush=True)

    tcp_ports = [5060]
    servers = []
    for port in tcp_ports:
        try:
            srv = await asyncio.start_server(
                lambda r, w, p=port: handle_tcp(r, w, wsl_ip, p),
                host=lan_ip,
                port=port,
            )
            servers.append(srv)
        except Exception as e:
            print(f"[Bridge] Warning binding TCP {port}: {e}", flush=True)

    try:
        await setup_sip_inbound()
    except Exception as e:
        print(f"[Bridge] SIP setup note: {e}", flush=True)

    print(f"[Bridge] High-speed SIP (5060) and RTP (10000-10020) bridge active on {lan_ip}!", flush=True)
    await asyncio.Event().wait()


if __name__ == "__main__":
    asyncio.run(main())
