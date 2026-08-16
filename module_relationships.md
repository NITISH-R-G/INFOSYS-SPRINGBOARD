```mermaid
graph LR
    N0[main.py]
    N1[pytesseract]
    N0 --> N1
    N0[main.py]
    N2[PIL]
    N0 --> N2
    N0[main.py]
    N3[os]
    N0 --> N3
    N4[verify_auth_e2e.py]
    N5[requests]
    N4 --> N5
    N4[verify_auth_e2e.py]
    N6[json]
    N4 --> N6
    N4[verify_auth_e2e.py]
    N3[os]
    N4 --> N3
    N7[replace_currency.py]
    N3[os]
    N7 --> N3
    N7[replace_currency.py]
    N8[re]
    N7 --> N8
    N9[verify_key.py]
    N3[os]
    N9 --> N3
    N9[verify_key.py]
    N10[google.generativeai]
    N9 --> N10
    N9[verify_key.py]
    N11[dotenv]
    N9 --> N11
    N12[migrate_db.py]
    N13[sqlite3]
    N12 --> N13
    N12[migrate_db.py]
    N3[os]
    N12 --> N3
    N14[test_analyze.py]
    N15[urllib.request]
    N14 --> N15
    N14[test_analyze.py]
    N16[urllib.error]
    N14 --> N16
    N14[test_analyze.py]
    N6[json]
    N14 --> N6
    N17[test_llm.py]
    N18[asyncio]
    N17 --> N18
    N17[test_llm.py]
    N19[app.services.llm_service]
    N17 --> N19
    N20[verify_backend_e2e.py]
    N3[os]
    N20 --> N3
    N20[verify_backend_e2e.py]
    N21[sys]
    N20 --> N21
    N20[verify_backend_e2e.py]
    N18[asyncio]
    N20 --> N18
    N20[verify_backend_e2e.py]
    N6[json]
    N20 --> N6
    N20[verify_backend_e2e.py]
    N22[fitz]
    N20 --> N22
    N20[verify_backend_e2e.py]
    N23[app.services.ocr_service]
    N20 --> N23
    N20[verify_backend_e2e.py]
    N19[app.services.llm_service]
    N20 --> N19
    N20[verify_backend_e2e.py]
    N24[app.config]
    N20 --> N24
    N25[test_llm_direct.py]
    N18[asyncio]
    N25 --> N18
    N25[test_llm_direct.py]
    N19[app.services.llm_service]
    N25 --> N19
    N25[test_llm_direct.py]
    N26[traceback]
    N25 --> N26
    N0[main.py]
    N27[logging]
    N0 --> N27
    N0[main.py]
    N28[fastapi]
    N0 --> N28
    N0[main.py]
    N29[fastapi.middleware.cors]
    N0 --> N29
    N0[main.py]
    N30[contextlib]
    N0 --> N30
    N0[main.py]
    N31[config]
    N0 --> N31
    N0[main.py]
    N32[database]
    N0 --> N32
    N0[main.py]
    N33[routers]
    N0 --> N33
    N0[main.py]
    N34[exceptions]
    N0 --> N34
    N0[main.py]
    N35[uvicorn]
    N0 --> N35
    N36[exceptions.py]
    N37[uuid]
    N36 --> N37
    N36[exceptions.py]
    N27[logging]
    N36 --> N27
    N36[exceptions.py]
    N28[fastapi]
    N36 --> N28
    N36[exceptions.py]
    N38[fastapi.responses]
    N36 --> N38
    N39[config.py]
    N3[os]
    N39 --> N3
    N39[config.py]
    N40[pathlib]
    N39 --> N40
    N39[config.py]
    N11[dotenv]
    N39 --> N11
    N39[config.py]
    N41[pydantic_settings]
    N39 --> N41
    N42[celery_app.py]
    N43[celery]
    N42 --> N43
    N42[celery_app.py]
    N31[config]
    N42 --> N31
    N44[database.py]
    N45[datetime]
    N44 --> N45
    N44[database.py]
    N46[typing]
    N44 --> N46
    N44[database.py]
    N47[sqlalchemy]
    N44 --> N47
    %% Graph truncated for readability
    click N0 href "./CarContractApp/backend/app/main.py" "View source file"
    click N4 href "./CarContractApp/verify_auth_e2e.py" "View source file"
    click N7 href "./CarContractApp/flutter_app/replace_currency.py" "View source file"
    click N9 href "./CarContractApp/backend/verify_key.py" "View source file"
    click N12 href "./CarContractApp/backend/migrate_db.py" "View source file"
    click N14 href "./CarContractApp/backend/test_analyze.py" "View source file"
    click N17 href "./CarContractApp/backend/test_llm.py" "View source file"
    click N20 href "./CarContractApp/backend/verify_backend_e2e.py" "View source file"
    click N25 href "./CarContractApp/backend/test_llm_direct.py" "View source file"
    click N36 href "./CarContractApp/backend/app/exceptions.py" "View source file"
    click N39 href "./CarContractApp/backend/app/config.py" "View source file"
    click N42 href "./CarContractApp/backend/app/celery_app.py" "View source file"
    click N44 href "./CarContractApp/backend/app/database.py" "View source file"
```