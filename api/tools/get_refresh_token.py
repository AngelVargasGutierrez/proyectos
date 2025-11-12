import os
import time
import requests
from dotenv import load_dotenv

load_dotenv()
TENANT_ID = os.getenv("ONEDRIVE_TENANT_ID", os.getenv("TENANT_ID", "consumers"))
CLIENT_ID = os.getenv("ONEDRIVE_CLIENT_ID", os.getenv("CLIENT_ID", ""))

DEVICE_CODE_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/devicecode"
TOKEN_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"


def main():
    if not CLIENT_ID:
        print("[ERROR] Define ONEDRIVE_CLIENT_ID o CLIENT_ID en el entorno.")
        return

    # Solicitar device code con los permisos necesarios
    scopes = "offline_access Files.ReadWrite.All"
    r = requests.post(DEVICE_CODE_URL, data={"client_id": CLIENT_ID, "scope": scopes}, timeout=20)
    if r.status_code != 200:
        print("[ERROR] No se pudo solicitar device code:", r.status_code, r.text)
        return

    data = r.json()
    print("\n== Autorización requerida ==")
    print(data.get("message") or "Visita el enlace y usa el código.")
    print("Verification URL:", data.get("verification_uri"))
    print("User code:", data.get("user_code"))
    interval = int(data.get("interval", 5))
    device_code = data.get("device_code")

    print("\nEsperando confirmación...")
    while True:
        time.sleep(interval)
        tr = requests.post(
            TOKEN_URL,
            data={
                "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                "client_id": CLIENT_ID,
                "device_code": device_code,
            },
            timeout=20,
        )
        if tr.status_code == 200:
            tokens = tr.json()
            refresh = tokens.get("refresh_token")
            access = tokens.get("access_token")
            print("\n== Tokens obtenidos ==")
            print("Refresh Token:\n", refresh)
            print("\n(Guárdalo en api/.env como ONEDRIVE_REFRESH_TOKEN)")
            print("\nAccess Token (temporal):\n", access[:64], "... (truncado)")
            break
        elif tr.status_code in (400, 401):
            # Mientras el usuario no completa, Graph devuelve authorization_pending / slow_down
            err = (tr.json() or {}).get("error")
            if err in ("authorization_pending", "slow_down"):
                continue
            print("[ERROR] Token request:", tr.status_code, tr.text)
            break
        else:
            print("[ERROR] Token request:", tr.status_code, tr.text)
            break


if __name__ == "__main__":
    main()