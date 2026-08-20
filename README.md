Set Login Screen for Pixie [https://github.com/xCaptaiN09/pixie-sddm]
sudo cp ~/Downloads/YOUR_FILENAME_HERE.jpg /usr/share/sddm/themes/pixie/assets/background.jpg
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/pixie
sudo systemctl restart sddm



Set HyDE wallpaper
cp ~/Downloads/XXXXXXX.png ~/Pictures/wallpapers/ 
~/.local/lib/hyde/wallpaper.sh --set "/home/supra13/Pictures/wallpapers/XXXXXXX.png"

Set fastfetch icon with HyDE
nano ~/.config/fastfetch/config.jsonc
"logo": {
    "source": "/home/supra13/.config/fastfetch/logo/pochita.icon",
    "height": 18
},








wleave - Prefer layout 2 4 based

mv ~/.config/wleave/layout_2 ~/.config/wleave/layout
mv ~/.config/wleave/style_2.css ~/.config/wleave/style.css