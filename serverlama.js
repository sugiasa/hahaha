require("dotenv").config();
const express = require("express");
const passport = require("passport");
const session = require("express-session");
const cors = require("cors");
const GoogleStrategy = require("passport-google-oauth20").Strategy;

// Konfigurasi server
const PORT = process.env.PORT || 7357;
const FRONTEND_URL = process.env.FRONTEND_URL || "http://localhost:3000";
const SESSION_SECRET = process.env.SESSION_SECRET || "rahasia-aplikasi-default";
const NODE_ENV = process.env.NODE_ENV || "development";
const isProduction = NODE_ENV === "production";

// Konfigurasi Google OAuth
const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID || "204512844580-47jivbvbsrf0ncg12qfd3chv0r97pni4.apps.googleusercontent.com";
const GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET || "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";
const GOOGLE_CALLBACK_URL = `http://localhost:${PORT}/auth/google/callback`;

// Inisialisasi Express
const app = express();
app.use(express.json());
app.use(cors({
  origin: FRONTEND_URL,
  credentials: true
}));

// Konfigurasi Session
app.use(
  session({ 
    secret: SESSION_SECRET,
    resave: false, 
    saveUninitialized: true,
    cookie: { 
      secure: isProduction, // Gunakan secure cookie di production (HTTPS)
      maxAge: 24 * 60 * 60 * 1000 // 24 jam
    }
  })
);

app.use(cors({
  origin: [FRONTEND_URL, "http://localhost:3000", "http://127.0.0.1:7357"],
  credentials: true
}));
app.use(passport.initialize());
app.use(passport.session());

// Output konfigurasi server saat startup
console.log(`[🚀 Server] Mode: ${NODE_ENV}`);
console.log(`[🚀 Server] Frontend URL: ${FRONTEND_URL}`);
console.log(`[🚀 Server] Google OAuth Callback: ${GOOGLE_CALLBACK_URL}`);

// Pastikan kredensial Google OAuth tersedia
if (!GOOGLE_CLIENT_ID || !GOOGLE_CLIENT_SECRET) {
  console.error("[❌ ERROR] GOOGLE_CLIENT_ID atau GOOGLE_CLIENT_SECRET tidak ditemukan di file .env");
  console.error("[❌ ERROR] Autentikasi Google OAuth tidak akan berfungsi");
}

// 🔹 Konfigurasi Passport Google OAuth
passport.use(
  new GoogleStrategy(
    {
      clientID: GOOGLE_CLIENT_ID,
      clientSecret: GOOGLE_CLIENT_SECRET,
      callbackURL: GOOGLE_CALLBACK_URL,
      scope: ["profile", "email"],
    },
    async (accessToken, refreshToken, profile, done) => {
      try {
        console.log("[🔍 Debug] Google profile data received:", JSON.stringify(profile, null, 2));
        
        // Pastikan data profil memiliki semua properti yang diperlukan
        if (!profile || !profile.id) {
          console.error("[❌ Error] Profile data invalid or incomplete");
          return done(new Error("Invalid profile data"), null);
        }
        
        // Pastikan email tersedia
        const email = profile.emails && profile.emails.length > 0 
          ? profile.emails[0].value 
          : "email not available";
        
        // Pastikan photo tersedia
        const photoURL = profile.photos && profile.photos.length > 0
          ? profile.photos[0].value
          : "https://ui-avatars.com/api/?name=" + encodeURIComponent(profile.displayName || "User") + "&background=random";
          
        // Data user dari Google OAuth
        const userData = {
          uid: profile.id,
          displayName: profile.displayName || "User",
          email: email,
          photoURL: photoURL,
          waktuLogin: new Date().toISOString(),
          provider: "google"
        };

        console.log(`[📌 Info] Data user diterima dari Google: ${userData.displayName} (${userData.email})`);
        return done(null, userData);
      } catch (error) {
        console.error(`[❌ Error] Error saat memproses profil Google:`, error);
        return done(error, null);
      }
    }
  )
);

passport.serializeUser((user, done) => {
  // Simpan hanya uid dan email di session untuk keamanan
  done(null, { 
    uid: user.uid, 
    email: user.email, 
    displayName: user.displayName,
    photoURL: user.photoURL 
  });
});

passport.deserializeUser((user, done) => {
  // Langsung kembalikan data user dari session
  done(null, user);
});

// 🔹 Middleware untuk cek autentikasi
const isAuthenticated = (req, res, next) => {
  if (req.isAuthenticated()) {
    return next();
  }
  res.status(401).json({ error: "Anda harus login terlebih dahulu" });
};

// 🔹 Endpoint untuk aplikasi Flutter Windows
app.get("/auth/windows/login", (req, res) => {
  // Generate URL untuk Google login dengan callback khusus Windows
  const authURL = `/auth/google?windows_redirect=true`;
  
  // Redirect ke Google login
  res.redirect(authURL);
});

// 🔹 Rute untuk login Google
app.get("/auth/google", (req, res, next) => {
  // Simpan parameter redirect_windows di state jika ada
  const isWindowsRedirect = req.query.windows_redirect === "true";
  const state = isWindowsRedirect ? "windows" : undefined;
  
  passport.authenticate("google", { 
    state: state
  })(req, res, next);
});


// 🔹 Callback setelah login berhasil
app.get(
  "/auth/google/callback",
  passport.authenticate("google", { failureRedirect: "/auth/failed" }),
  (req, res) => {
    try {
      // Data yang akan dikirim ke Flutter
      const userData = {
        uid: req.user.uid,
        displayName: req.user.displayName,
        email: req.user.email,
        photoURL: req.user.photoURL,
        token: req.sessionID,
        timestamp: new Date().toISOString()
      };
      
      // Encode data sebagai parameter URL yang aman
      const encodedData = encodeURIComponent(JSON.stringify(userData));
      
      // Tampilkan halaman dengan auto-redirect ke custom protocol
      res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Login Berhasil</title>
          <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; display: flex; justify-content: center; align-items: center; min-height: 100vh; background: #f5f5f5; }
            .container { width: 90%; max-width: 500px; text-align: center; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .success-icon { font-size: 70px; color: #34A853; margin-bottom: 20px; }
            .loading { display: inline-block; width: 30px; height: 30px; border: 3px solid rgba(0,0,0,0.2); border-radius: 50%; border-top-color: #4285F4; animation: spin 1s ease-in-out infinite; margin-right: 10px; }
            @keyframes spin { to { transform: rotate(360deg); } }
            .btn { display: inline-block; background: #4285F4; color: white; padding: 12px 24px; border-radius: 5px; text-decoration: none; font-weight: bold; cursor: pointer; border: none; font-size: 16px; margin-top: 20px; }
            .manual-btn { background: #757575; margin-top: 10px; }
            .redirect-msg { margin: 15px 0; color: #555; }
            #countdown { font-weight: bold; color: #4285F4; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="success-icon">✓</div>
            <h1>Login Berhasil!</h1>
            <p>Selamat datang, ${req.user.displayName}!</p>
            
            <div class="redirect-msg">
              <div class="loading"></div>
              Mengarahkan ke aplikasi dalam <span id="countdown">3</span> detik...
            </div>
            
            <a href="myapp://auth?data=${encodedData}" class="btn" id="openAppBtn">Buka Aplikasi Sekarang</a>
            <p style="margin-top: 20px; font-size: 14px; color: #666;">Jika aplikasi tidak terbuka secara otomatis, klik tombol di atas.</p>
          </div>
          
          <script>
            // Data untuk protocol handler
            const appData = ${JSON.stringify(userData)};
            const appUrl = "myapp://auth?data=${encodedData}";
            
            // Auto countdown dan redirect
            let seconds = 3;
            const countdownElement = document.getElementById('countdown');
            const countdown = setInterval(() => {
              seconds--;
              countdownElement.textContent = seconds;
              if (seconds <= 0) {
                clearInterval(countdown);
                redirectToApp();
              }
            }, 1000);
            
            // Fungsi untuk redirect ke aplikasi
            function redirectToApp() {
              console.log("Redirecting to app...");
              window.location.href = appUrl;
            }
            
            // Event listener untuk tombol manual
            document.getElementById('openAppBtn').addEventListener('click', function(e) {
              e.preventDefault();
              redirectToApp();
            });
          </script>
        </body>
        </html>
      `);
    } catch (err) {
      console.error("[❌ Error] Error saat menampilkan halaman konfirmasi:", err);
      res.status(500).send(`
        <h1>Terjadi Error</h1>
        <p>Mohon maaf, terjadi error saat memproses data:</p>
        <pre>${err.message}</pre>
        <a href="/">Kembali ke Halaman Utama</a>
      `);
    }
  }
);

// 🔹 Rute jika auth gagal
app.get("/auth/failed", (req, res) => {
  console.log("[❌ Error] Authentication failed");
  res.status(401).send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Login Gagal</title>
      <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f7f7f7; text-align: center; }
        .container { margin: 0 auto; max-width: 500px; background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .error-icon { font-size: 60px; color: #DB4437; margin-bottom: 20px; }
        .btn { display: inline-block; background: #4285F4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-top: 20px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="error-icon">❌</div>
        <h1>Login Gagal</h1>
        <p>Mohon maaf, terjadi masalah saat proses autentikasi.</p>
        <a href="/" class="btn">Kembali ke Halaman Utama</a>
      </div>
    </body>
    </html>
  `);
});

// 🔹 Rute untuk cek status login
app.get("/auth/status", (req, res) => {
  if (req.isAuthenticated()) {
    res.json({
      isLoggedIn: true,
      user: {
        uid: req.user.uid,
        email: req.user.email,
        displayName: req.user.displayName,
        photoURL: req.user.photoURL,
      }
    });
  } else {
    res.json({ isLoggedIn: false });
  }
});

// 🔹 Endpoint untuk mendapatkan data user
app.get("/api/user", isAuthenticated, (req, res) => {
  try {
    console.log("[🔍 Debug] Sending user data:", JSON.stringify(req.user, null, 2));
    res.json({
      success: true,
      user: req.user,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    console.error("[❌ Error] Error saat mengirim data user:", err);
    res.status(500).json({ 
      success: false, 
      error: "Server error", 
      message: err.message 
    });
  }
});

// 🔹 API endpoint untuk verifikasi token
app.post("/api/auth/verify", express.json(), (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        message: "Token tidak ditemukan"
      });
    }
    
    // Verifikasi token - implementasi sederhana
    // Di implementasi nyata, Anda akan memeriksa token terhadap session store
    return res.json({
      success: true,
      message: "Token valid",
      isValid: true
    });
  } catch (error) {
    console.error("[❌ Error] Verifikasi token error:", error);
    res.status(500).json({
      success: false,
      message: "Terjadi kesalahan server",
      error: error.message
    });
  }
});

// 🔹 Endpoint untuk logout
app.get("/auth/logout", (req, res) => {
  req.logout((err) => {
    if (err) {
      console.error("[❌ Error] Error saat logout:", err);
      return res.status(500).json({ error: "Terjadi kesalahan saat logout" });
    }
    console.log("[🚪 Info] User berhasil logout");
    res.redirect("/");
  });
});

// 🔹 Rute Home sederhana untuk testing
app.get("/", (req, res) => {
  // Periksa status login untuk menampilkan halaman yang sesuai
  if (req.isAuthenticated()) {
    // Fix untuk URL gambar yang bermasalah
    const photoURL = req.user.photoURL || "";
    // Gunakan gambar placeholder jika tidak ada URL foto atau URL bermasalah
    const displayPhoto = photoURL.startsWith("http") 
      ? photoURL 
      : "https://ui-avatars.com/api/?name=" + encodeURIComponent(req.user.displayName) + "&background=random";
    
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Google Auth Demo</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; background: #f7f7f7; }
          .container { margin: 0 auto; max-width: 600px; background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          img.profile { border-radius: 50%; object-fit: cover; width: 50px; height: 50px; }
          .header { margin-bottom: 25px; }
          .profile-section { display: flex; align-items: center; margin-bottom: 20px; }
          .profile-info { margin-left: 15px; }
          .buttons { margin-top: 25px; }
          .btn { display: inline-block; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin-right: 10px; color: white; }
          .data-btn { background: #34A853; }
          .logout-btn { background: #EA4335; }
          .windows-btn { background: #4285F4; margin-top: 15px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Server Autentikasi Google</h1>
          </div>
          <p>Anda sudah login dengan akun Google Anda:</p>
          <div class="profile-section">
            <div>
              <img src="${displayPhoto}" class="profile" alt="Foto Profil">
            </div>
            <div class="profile-info">
              <h3>${req.user.displayName}</h3>
              <p>${req.user.email}</p>
            </div>
          </div>
          <div class="buttons">
            <a href="/api/user" class="btn data-btn">Lihat Data User</a>
            <a href="/auth/logout" class="btn logout-btn">Logout</a>
          </div>
        </div>
      </body>
      </html>
    `);
  } else {
    res.send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Google Auth Demo</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; background: #f7f7f7; }
          .container { margin: 0 auto; max-width: 600px; background: white; padding: 25px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
          .header { margin-bottom: 25px; }
          .login-btn { display: inline-block; background: #4285F4; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-family: Arial; margin-top: 15px; }
          .windows-btn { display: inline-block; background: #0078D7; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; font-family: Arial; margin-top: 15px; margin-left: 10px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Server Autentikasi Google</h1>
          </div>
          <p>Server berjalan dengan baik. Silakan login menggunakan link di bawah:</p>
          <div>
            <a href="/auth/google" class="login-btn">Login dengan Google</a>
            <a href="/auth/windows/login" class="windows-btn">Login untuk Windows</a>
          </div>
        </div>
      </body>
      </html>
    `);
  }
});

// API endpoint untuk aplikasi Flutter
app.get("/api/auth/flutter/callback", (req, res) => {
  try {
    // Validasi token
    const token = req.query.token;
    if (!token) {
      return res.status(400).json({
        success: false,
        message: "Token tidak ditemukan"
      });
    }
    
    // Kirim data ke aplikasi Flutter
    res.json({
      success: true,
      user: req.user,
      token: token,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error("[❌ Error] Flutter callback error:", error);
    res.status(500).json({
      success: false,
      message: "Terjadi kesalahan server",
      error: error.message
    });
  }
});

// 🚀 Jalankan server
app.listen(PORT, () => {
  console.log(`[🚀 Server] Berjalan di http://localhost:${PORT}`);
  console.log(`[🚀 Server] URL Login Google: http://localhost:${PORT}/auth/google`);
  console.log(`[🚀 Server] URL Login Windows: http://localhost:${PORT}/auth/windows/login`);
});