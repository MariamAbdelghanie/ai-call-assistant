import os
import asyncio
from dotenv import load_dotenv
from livekit import api

load_dotenv()


async def setup_sip_inbound():
    url = os.getenv("LIVEKIT_URL", "http://127.0.0.1:7880").replace("ws://", "http://")
    api_key = os.getenv("LIVEKIT_API_KEY", "devkey")
    api_secret = os.getenv("LIVEKIT_API_SECRET", "secret")

    lkapi = api.LiveKitAPI(url=url, api_key=api_key, api_secret=api_secret)

    try:
        existing_rules = await lkapi.sip.list_dispatch_rule(
            api.ListSIPDispatchRuleRequest()
        )
        for r in existing_rules.items:
            await lkapi.sip.delete_dispatch_rule(
                api.DeleteSIPDispatchRuleRequest(sip_dispatch_rule_id=r.sip_dispatch_rule_id)
            )

        existing_trunks = await lkapi.sip.list_inbound_trunk(
            api.ListSIPInboundTrunkRequest()
        )
        for t in existing_trunks.items:
            await lkapi.sip.delete_sip_trunk(
                api.DeleteSIPTrunkRequest(sip_trunk_id=t.sip_trunk_id)
            )

        trunk_req = api.CreateSIPInboundTrunkRequest(
            trunk=api.SIPInboundTrunkInfo(
                name="Local-SIP-Trunk",
                allowed_addresses=["0.0.0.0/0"],
                media_encryption=api.SIPMediaEncryption.SIP_MEDIA_ENCRYPT_ALLOW,
            )
        )
        trunk = await lkapi.sip.create_inbound_trunk(trunk_req)
        trunk_id = trunk.sip_trunk_id
        print(f"[SIP] Created Inbound Trunk (SRTP+RTP allowed): {trunk_id}")

        rule_req = api.CreateSIPDispatchRuleRequest(
            rule=api.SIPDispatchRule(
                dispatch_rule_individual=api.SIPDispatchRuleIndividual(
                    room_prefix="call-",
                )
            ),
            name="SIP-To-AI-Room",
            trunk_ids=[trunk_id],
        )
        rule = await lkapi.sip.create_dispatch_rule(rule_req)
        print(f"[SIP] Created Dispatch Rule: {rule.sip_dispatch_rule_id}")
        print("[SIP] LiveKit SIP Server is ready for Linphone & Zoiper calls!")
    finally:
        await lkapi.aclose()


if __name__ == "__main__":
    asyncio.run(setup_sip_inbound())
