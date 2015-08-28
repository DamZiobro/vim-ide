#!/bin/bash 


VIM_ROOT=$HOME/.vim
RANDOM_NR=`shuf -i 1000-90000 -n 1`
INSTALL_ROOT=`pwd`

if [ -d $VIM_ROOT -o -L $VIM_ROOT ]; then 
    mv $VIM_ROOT $HOME/.vim_$RANDOM_NR
fi 

cd 
#checking whether install from vim-ide dir or dotfiles
BASE_INSTALL_DIR=`basename $INSTALL_ROOT`
if [ $BASE_INSTALL_DIR == "vim-ide" ];
then
    mv $INSTALL_ROOT $VIM_ROOT
else 
    ln -s $INSTALL_ROOT $VIM_ROOT
fi

if [ -f $HOME/.vimrc -o -L $HOME/.vimrc ]; then 
    mv $HOME/.vimrc $HOME/.vimrc_$RANDOM_NR
fi

ln -s $VIM_ROOT/vimrc $HOME/.vimrc

echo -e "Installing vim (Vi Improved) package from repository"
#installinv vim-gnome allows copy/pasting beween vim and system clipboard
sudo apt-get --yes install vim vim-gnome

echo -e "Installing ctags"
sudo apt-get --yes install ctags

echo -e "Installing ctags"
sudo apt-get --yes install cscope

echo -e "Initializing and checking out plugins submodules: "


cd $VIM_ROOT 
git submodule init 
git submodule update 
git submodule foreach git checkout master
git submodule foreach git pull origin master

echo -e "Installing vi_overlay" 
while true; do
    yn=y
    if [ "$1" != "y" ]; then 
        read -p "Do you wish to install vi_overlay (sudo priviledges are required)? [y/n]: " yn
    fi 
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

