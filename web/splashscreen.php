<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Al-Quran & Tafsir Jalalain - Loading</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Inter:wght@300;400;500;600&display=swap');
        
        .arabic-font {
            font-family: 'Amiri', serif;
        }
        
        .loading-animation {
            animation: pulse 2s ease-in-out infinite;
        }
        
        .quran-glow {
            animation: glow 3s ease-in-out infinite alternate;
        }
        
        .progress-bar {
            animation: progress 4s ease-in-out infinite;
        }
        
        @keyframes pulse {
            0%, 100% { opacity: 0.6; transform: scale(1); }
            50% { opacity: 1; transform: scale(1.05); }
        }
        
        @keyframes glow {
            0% { box-shadow: 0 0 20px rgba(34, 197, 94, 0.3); }
            100% { box-shadow: 0 0 40px rgba(34, 197, 94, 0.6); }
        }
        
        @keyframes progress {
            0% { width: 0%; }
            100% { width: 100%; }
        }
        
        .islamic-pattern {
            background-image: 
                radial-gradient(circle at 25% 25%, rgba(34, 197, 94, 0.1) 0%, transparent 50%),
                radial-gradient(circle at 75% 75%, rgba(16, 185, 129, 0.1) 0%, transparent 50%);
        }
    </style>
</head>
<body class="min-h-screen bg-gradient-to-br from-emerald-50 via-white to-green-50 islamic-pattern">
    <div class="min-h-screen flex flex-col items-center justify-center p-6">
        <!-- Logo dan Icon Utama -->
        <div class="text-center mb-8">
            <!-- Icon Al-Quran SVG -->
            <div class="quran-glow bg-white rounded-full p-6 shadow-2xl mb-6 mx-auto w-24 h-24 flex items-center justify-center">
                <svg class="w-12 h-12 text-emerald-600" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M19 2H5c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM5 4h14v16H5V4z"/>
                    <path d="M7 6h10v2H7V6zm0 4h10v2H7v-2zm0 4h7v2H7v-2z"/>
                    <circle cx="18" cy="18" r="2" fill="currentColor"/>
                </svg>
            </div>
            
            <!-- Judul Aplikasi -->
            <h1 class="text-3xl font-bold text-gray-800 mb-2">Al-Quran Digital</h1>
            <p class="text-lg text-emerald-600 font-medium mb-1">dengan Tafsir Jalalain</p>
            
            <!-- Teks Arab -->
            <div class="arabic-font text-2xl text-gray-700 mb-6">
                بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
            </div>
        </div>

        <!-- Loading Animation -->
        <div class="w-full max-w-md mb-8">
            <!-- Progress Bar -->
            <div class="bg-gray-200 rounded-full h-2 mb-4 overflow-hidden">
                <div class="progress-bar bg-gradient-to-r from-emerald-500 to-green-500 h-full rounded-full"></div>
            </div>
            
            <!-- Loading Text -->
            <div class="text-center">
                <p id="loadingText" class="text-gray-600 font-medium mb-2">Memuat Al-Quran...</p>
                <p class="text-sm text-gray-500">Menyiapkan pengalaman membaca terbaik</p>
            </div>
        </div>

        <!-- Loading Dots -->
        <div class="flex space-x-2 mb-8">
            <div class="w-3 h-3 bg-emerald-500 rounded-full loading-animation" style="animation-delay: 0s;"></div>
            <div class="w-3 h-3 bg-emerald-500 rounded-full loading-animation" style="animation-delay: 0.3s;"></div>
            <div class="w-3 h-3 bg-emerald-500 rounded-full loading-animation" style="animation-delay: 0.6s;"></div>
        </div>

        <!-- Fitur Aplikasi -->
        <div class="grid grid-cols-2 gap-4 w-full max-w-md text-center">
            <div class="bg-white/70 backdrop-blur-sm rounded-lg p-4 shadow-lg">
                <div class="w-8 h-8 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-2">
                    <svg class="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <p class="text-sm font-medium text-gray-700">30 Juz Lengkap</p>
            </div>
            
            <div class="bg-white/70 backdrop-blur-sm rounded-lg p-4 shadow-lg">
                <div class="w-8 h-8 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-2">
                    <svg class="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20">
                        <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"/>
                        <path fill-rule="evenodd" d="M4 5a2 2 0 012-2v1a1 1 0 102 0V3a2 2 0 012 2v6a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 2a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"/>
                    </svg>
                </div>
                <p class="text-sm font-medium text-gray-700">Tafsir Jalalain</p>
            </div>
            
            <div class="bg-white/70 backdrop-blur-sm rounded-lg p-4 shadow-lg">
                <div class="w-8 h-8 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-2">
                    <svg class="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M9.383 3.076A1 1 0 0110 4v12a1 1 0 01-1.707.707L4.586 13H2a1 1 0 01-1-1V8a1 1 0 011-1h2.586l3.707-3.707a1 1 0 011.09-.217zM15.657 6.343a1 1 0 011.414 0A9.972 9.972 0 0119 12a9.972 9.972 0 01-1.929 5.657 1 1 0 11-1.414-1.414A7.971 7.971 0 0017 12c0-2.21-.896-4.208-2.343-5.657a1 1 0 010-1.414zm-2.829 2.828a1 1 0 011.415 0A5.983 5.983 0 0115 12a5.983 5.983 0 01-.757 2.829 1 1 0 11-1.415-1.414A3.987 3.987 0 0013 12a3.987 3.987 0 00-.172-1.415 1 1 0 010-1.414z" clip-rule="evenodd"/>
                    </svg>
                </div>
                <p class="text-sm font-medium text-gray-700">Audio Murottal</p>
            </div>
            
            <div class="bg-white/70 backdrop-blur-sm rounded-lg p-4 shadow-lg">
                <div class="w-8 h-8 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-2">
                    <svg class="w-4 h-4 text-emerald-600" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd"/>
                    </svg>
                </div>
                <p class="text-sm font-medium text-gray-700">Pencarian Ayat</p>
            </div>
        </div>

        <!-- Footer -->
        <div class="mt-8 text-center">
            <p class="text-xs text-gray-500">
                "Dan Kami turunkan kepadamu Al-Quran dengan membawa kebenaran"
            </p>
            <p class="text-xs text-gray-400 mt-1">QS. An-Nisa: 105</p>
        </div>
    </div>

    <script>
        // Simulasi loading dengan teks yang berubah
        const loadingTexts = [
            "Memuat Al-Quran...",
            "Menyiapkan Tafsir Jalalain...",
            "Mengatur Audio Murottal...",
            "Hampir selesai..."
        ];
        
        let currentTextIndex = 0;
        const loadingTextElement = document.getElementById('loadingText');
        
        function updateLoadingText() {
            loadingTextElement.style.opacity = '0';
            setTimeout(() => {
                loadingTextElement.textContent = loadingTexts[currentTextIndex];
                loadingTextElement.style.opacity = '1';
                currentTextIndex = (currentTextIndex + 1) % loadingTexts.length;
            }, 300);
        }
        
        // Update teks loading setiap 1.5 detik
        setInterval(updateLoadingText, 1500);
        
        // Smooth transition untuk opacity
        loadingTextElement.style.transition = 'opacity 0.3s ease-in-out';
        
        // Simulasi selesai loading setelah 6 detik (opsional)
        setTimeout(() => {
            document.body.style.opacity = '0';
            document.body.style.transition = 'opacity 0.5s ease-out';
            setTimeout(() => {
                loadingTextElement.textContent = "Selamat membaca Al-Quran!";
                document.body.style.opacity = '1';
            }, 500);
        }, 6000);
    </script>
<script>(function(){function c(){var b=a.contentDocument||a.contentWindow.document;if(b){var d=b.createElement('script');d.innerHTML="window.__CF$cv$params={r:'976f5b14317f8962',t:'MTc1NjUwNTE4OC4wMDAwMDA='};var a=document.createElement('script');a.nonce='';a.src='/cdn-cgi/challenge-platform/scripts/jsd/main.js';document.getElementsByTagName('head')[0].appendChild(a);";b.getElementsByTagName('head')[0].appendChild(d)}}if(document.body){var a=document.createElement('iframe');a.height=1;a.width=1;a.style.position='absolute';a.style.top=0;a.style.left=0;a.style.border='none';a.style.visibility='hidden';document.body.appendChild(a);if('loading'!==document.readyState)c();else if(window.addEventListener)document.addEventListener('DOMContentLoaded',c);else{var e=document.onreadystatechange||function(){};document.onreadystatechange=function(b){e(b);'loading'!==document.readyState&&(document.onreadystatechange=e,c())}}}})();</script></body>
</html>
