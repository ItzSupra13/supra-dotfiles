<!-- Change the wallpaper -->
sudo cp ~/Downloads/YOUR_FILENAME.jpg /usr/share/sddm/themes/pixie/assets/background.jpg

<!-- Change the avatar -->
sudo cp ~/Downloads/YOUR_AVATAR.jpg /usr/share/sddm/themes/pixie/assets/avatar.jpg

<!-- Test it -->
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie

<!-- Restart Device -->
sudo systemctl restart sddm