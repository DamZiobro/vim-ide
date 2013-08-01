mv ~/.vim ~/.vimBackup
cp -r * ~/.vim
cd
ln -s .vim/vimrc .vimrc

echo -e "Installing ctags"
sudo apt-get install ctags
