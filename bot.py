import os, json, random, string, urllib.request, base64

BOT_TOKEN = os.environ["BOT_TOKEN"]
GH_TOKEN = os.environ["GH_TOKEN"]
ADMIN_ID = "7121620348"
REPO = "alphasuper6-dev/alpha_super"

def tg_req(method, data=None):
    url = f"https://telegram.org{BOT_TOKEN}/{method}"
    req = urllib.request.Request(url, data=json.dumps(data).encode() if data else None, headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req).read().decode())

def gh_file(path, new_content=None, sha=None):
    url = f"https://github.com{REPO}/contents/{path}"
    headers = {"Authorization": f"token {GH_TOKEN}", "Accept": "application/vnd.github.v3+json"}
    if new_content is None:
        res = json.loads(urllib.request.urlopen(urllib.request.Request(url, headers=headers)).read().decode())
        return json.loads(base64.b64decode(res["content"]).decode()), res["sha"]
    else:
        payload = {"message": f"Update {path}", "content": base64.b64encode(json.dumps(new_content, ensure_ascii=False, indent=2).encode()).decode(), "sha": sha}
        urllib.request.urlopen(urllib.request.Request(url, data=json.dumps(payload).encode(), headers=headers, method="PUT"))

def gen_code(prefix="AS"):
    return f"{prefix}-" + "".join(random.choices(string.ascii_uppercase + string.digits, k=6))

def main():
    state, state_sha = gh_file("bot_state.json")
    codes, codes_sha = gh_file("codes.json")
    updates = tg_req("getUpdates", {"offset": state.get("offset", 0), "timeout": 10}).get("result", [])
    
    changed_codes = False
    for u in updates:
        state["offset"] = u["update_id"] + 1
        msg = u.get("message", {})
        chat_id = str(msg.get("chat", {}).get("id", ""))
        text = msg.get("text", "")
        if not chat_id: continue

        if chat_id == ADMIN_ID and text == "/gen":
            c = gen_code("AS")
            codes[c] = {"deviceId": "", "status": "Unused", "by": "Admin"}
            changed_codes = True
            tg_req("sendMessage", {"chat_id": chat_id, "text": f"✅ كود جديد (150 ألف ل.س):\n`{c}`", "parse_mode": "Markdown"})
        elif text.startswith("/start"):
            parts = text.split(" ")
            ref = parts if len(parts) > 1 else ""
            users = state.setdefault("users", {})
            if chat_id not in users:
                users[chat_id] = {"invites": 0, "rewarded": False}
                if ref and ref != chat_id and ref in users:
                    users[ref]["invites"] += 1
                    cnt = users[ref]["invites"]
                    tg_req("sendMessage", {"chat_id": ref, "text": f"🎉 انضم صديق عبر رابطك! رصيدك الآن: {cnt}/4"})
                    if cnt >= 4 and not users[ref]["rewarded"]:
                        fc = gen_code("FREE")
                        codes[fc] = {"deviceId": "", "status": "Unused", "by": f"Ref:{ref}"}
                        users[ref]["rewarded"] = True
                        changed_codes = True
                        tg_req("sendMessage", {"chat_id": ref, "text": f"🎁 مبروك! أكملت 4 دعوات. كودك المجاني:\n`{fc}`", "parse_mode": "Markdown"})
            tg_req("sendMessage", {"chat_id": chat_id, "text": "أهلاً بك في Alpha Super 🎓\n\nللحصول على الباقة الشاملة (تاسع + بكالوريا):\n1️⃣ أرسل كلمة: رابط الدعوة (وادعُ 4 أصدقاء لكود مجاني).\n2️⃣ أو تواصل مع الإدارة للاشتراك بـ 150 ألف ل.س."})
        elif text == "رابط الدعوة":
            tg_req("sendMessage", {"chat_id": chat_id, "text": f"شارك رابطك مع 4 أصدقاء للحصول على كود مجاني:\nhttps://t.me{chat_id}"})

    if changed_codes: gh_file("codes.json", codes, codes_sha)
    if updates: gh_file("bot_state.json", state, state_sha)

if __name__ == "__main__":
    main()
  
