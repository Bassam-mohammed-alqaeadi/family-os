import { spawn } from 'child_process';

const API_KEY = "AIzaSyD3h6YHAUEcsikQBikBA_10NdZFr3lap6c";
const BASE_URL = "https://family-os-staging-api.onrender.com";

async function run() {
    console.log("🚀 AntiGravity Auto-Execution: Device Telemetry Phase 1\n");

    try {
        console.log("⏳ Fetching 4 FRESH Firebase Tokens...");
        const tokens = [];
        for (let i = 1; i <= 4; i++) {
            const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: `test_telemetry_${Date.now()}_${i}@test.com`, password: 'password123', returnSecureToken: true })
            });
            const data = await res.json();
            tokens.push(data.idToken);
        }
        console.log("✅ Tokens fetched successfully!\n");

        console.log("⚙️ Running Staging Verifier for Device Telemetry...\n");

        // تمرير المفاتيح مباشرة كما طلب النظام الجديد
        const env = {
            ...process.env,
            STAGING_BASE_URL: BASE_URL,
            STAGING_PRIMARY_GUARDIAN_TOKEN: tokens[0],
            STAGING_CO_GUARDIAN_TOKEN: tokens[1],
            STAGING_CHILD_TOKEN: tokens[2],
            STAGING_UNRELATED_TOKEN: tokens[3]
        };

        // تشغيل الفحص آلياً
        const child = spawn('npm', ['run', 'verify:staging:device-telemetry'], {
            env,
            stdio: 'inherit',
            shell: true
        });

        child.on('close', (code) => {
            console.log(`\n🔒 Verification process finished with exit code ${code}.`);
        });

    } catch (err) {
        console.error("❌ Error:", err);
    }
}

run();