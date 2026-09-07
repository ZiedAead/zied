@echo off
title رفع المشروع إلى GitHub
chcp 65001 > nul
cls
cd /d "c:\Users\Zied Aead\Desktop\zied"

echo ====================================================
echo      رفع تطبيق زيد اياد للديون إلى GitHub
echo ====================================================
echo.
echo جاري رفع الكود إلى:
echo https://github.com/ZiedAead/zied.git
echo.
echo إذا ظهرت لك نافذة تسجيل الدخول إلى GitHub، اضغط Sign in with browser.
echo ====================================================
echo.

"C:\Program Files\Git\cmd\git.exe" push -u origin main

echo.
echo ====================================================
if %ERRORLEVEL% EQU 0 (
    echo تم رفع المشروع بنجاح!
    echo يمكنك الآن فتح تبويب Actions في GitHub لتحميل ملف الـ IPA فور انتهاء البناء.
) else (
    echo حدث خطأ أثناء الرفع، تأكد من تسجيل دخولك بحساب GitHub الخاص بك.
)
echo ====================================================
pause
