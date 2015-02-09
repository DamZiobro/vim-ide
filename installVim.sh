#!/bin/bash 

VIM_ROOT=$HOME/.vim
RANDOM_NR=`shuf -i 1000-90000 -n 1`
INSTALL_ROOT=`pwd`

if [ -d $VIM_ROOT ]; then 
    mv $VIM_ROOT $HOME/.vim_$RANDOM_NR
fi 

cd 
mv $INSTALL_ROOT $VIM_ROOT
cd $VIM_ROOT
if [ -f $HOME/.vimrc ]; then 
    rm $HOME/.vimrc
fi

ln -s $VIM_ROOT/vimrc $HOME/.vimrc

echo -e "Installing vim (Vi Improved) package from repository"
sudo apt-get install vim vim-gnome

echo -e "Installing ctags"
sudo apt-get install ctags

echo -e "Initializing and checking out plugins submodules: "
cd $VIM_ROOT 
git submodule init 
git submodule update 

echo -e "Installing vi_overlay" 
while true; do
    read -p "Do you wish to install vi_overlay (sudo priviledges are required)? [y/n]: " yn
    case $yn in 
        [Yy]* ) echo -e "Yes selected";
                if [ -f /usr/bin/vi.default ]; then 
                    sudo rm /usr/bin/vi.default
                fi
                if [ -f /usr/bin/vim.default ]; then 
                    sudo rm /usr/bin/vim.default
                fi
                sudo ln -s /etc/alternatives/vi /usr/bin/vi.default
                sudo ln -s /etc/alternatives/vim /usr/bin/vim.default 
                if [ -f /usr/bin/vi ]; then 
                    sudo rm /usr/bin/vi 
                fi 
                if [ -f /usr/bin/vim ]; then 
                    sudo rm /usr/bin/vim 
                fi 
                if [ -f $HOME/.vim/vimscripts/vi_overlay ]; then 
                    sudo ln -s $VIM_ROOT/vimscripts/vi_overlay /usr/bin/vi
                    sudo ln -s $VIM_ROOT/vimscripts/vi_overlay /usr/bin/vim 
                    sudo chmod +x $VIM_ROOT/vimscripts/vi_overlay
                else 
                    echo -e "WARNING!!! $HOME/.vim/vimscripts/vi_overlay does not exist..."
                fi
                echo -e "vi_overlay installed.";
                break;;
        [Nn]* ) echo -e "No selected"; break;;
        * ) echo -e "Please select yes or no";;
    esac
done
