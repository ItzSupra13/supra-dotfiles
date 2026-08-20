<!-- Change the wallpaper -->
sudo cp ~/Downloads/YOUR_FILENAME_HERE.jpg /usr/share/sddm/themes/pixie/assets/background.jpg

<!-- Test it -->
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie

<!-- Restart Device -->
sudo systemctl restart sddm