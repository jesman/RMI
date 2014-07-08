#!/bin/bash
myos=`uname`
RPDIR=/tmp/ # just put the packages into a tmp directory 
RLDIR=$1 # library directory
INSTALLR=0
INSTALLRPKG=0
if [[ ${#RLDIR} -le 0 ]]  ; then 
  echo "This will install R and ANTsR as well - if you want only ANTsR then set 2nd / 3rd argument to zero "
  echo " but we assume you installed a compatible version of R."
  echo "usage is : "
  echo $0  ANTSRDIR 1_or_0_R   1_or_0_R_pkgs
  echo  where ANTSRDIR is an absolute path where you want to put R packages and ANTsR
  echo  the 2 booleans control whether you install R or R_pkgs that are needed by ANTsR
  echo  $0  ~/RLibraries/ 0 1 
  exit 1 
fi
if [[ $# -gt 1 ]] ; then 
  INSTALLR=$2
fi
if [[ $# -gt 2 ]] ; then 
  INSTALLRPKG=$3
fi
echo will install R? $INSTALLR
echo will install R_PKG? $INSTALLRPKG
if [[ $myos == "Linux" ]] && [[ $INSTALLR -gt 0 ]] ; then
  #Which update manager to use?
  command -v yum > /dev/null 2>/dev/null
  useapt=$?
  if [ $useapt -eq 1 ]; then
    #use apt-get
    sudo apt-get install build-essential git subversion cmake-curses-gui xorg libx11-dev freeglut3 freeglut3-dev
    if [[ $INSTALLR -gt 0 ]] ; then 
      sudo apt-get install r-base r-base-dev 
    fi
  else
    #Use yum, e.g. for RHEL/CentOS/Fedora. Requires different package names
    echo "yum manager found. See the script for commands to run manually, as they have not yet been "
    echo "tested on a clean install, and they assume RHEL/CentOS 6."
    exit 1;
    #Experimental...
    sudo yum groupinstall "Development Tools"
    sudo yum groupinstall "X Window System"
    sudo yum install git-core mod_dav_svn subversion cmake cmake-gui freeglut freeglut-devel
    if [[ $INSTALLR -gt 0 ]] ; then
      #NOTE: this epel repo install is for RHEL/Centos 6
      su -c 'rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
      #NOTE that above for apt-get, 'install' is not called. Bug?
      sudo yum install R
    fi
  fi
fi 
#
if [[ $myos == "Darwin" ]]  && [[ $INSTALLR -ge 1 ]] ; then
# get homebrew 
  ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
  brew update
  brew prune
  brew install wget 
  brew install git 
  brew install gfortran 
  brew install CMake 
  if [[ ${#R_LD_LIBRARY_PATH} -gt 0 ]] ; then 
    echo "R_LD_LIBRARY_PATH should not be set.  This may cause R installation problems."
  fi
  if [[ $INSTALLR -gt 0 ]] ; then 
    brew tap homebrew/science
    brew install R
  fi
  if [[ -s ~/.profile ]] ; then 
    echo 'export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"' >> ~/.profile
  else 
    echo 'export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"' >> ~/.bash_profile
  fi
# set these correctly for a pure homebrew install .... 
#  RLDIR=/usr/local/opt/r/R.framework/Libraries/
  if [[ ! -s $RLDIR ]] ; then 
    mkdir -p $RLDIR 
  fi 
  echo i am using the homebrew R library directory $RLDIR 
fi
command -v wget >/dev/null 2>&1 || { echo >&2 "I require wget but it's not installed.  Aborting."; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "I require git but it's not installed.  Aborting."; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo >&2 "I require cmake but it's not installed.  Aborting."; exit 1; }
command -v R >/dev/null 2>&1 || { echo >&2 "I require R but it's not installed.  Aborting."; exit 1; }  
echo "Grabbing and installing ANTsR dependencies"

if [ ! -d "$RPDIR" ]; then
  mkdir $RPDIR
fi

if [ ! -d "$RLDIR" ]; then
  mkdir $RLDIR
fi

cd $RPDIR
if [[ $INSTALLRPKG == 1 ]] ; then 
R --no-save <<RSCRIPT
local({r <- getOption("repos"); 
       r["CRAN"] <- "http://cran.r-project.org"; options(repos=r)})
install.packages("Rcpp",type="source")
mypkg<-c("signal","timeSeries","mFilter","fastICA","MASS","robust","magic","knitr","pixmap","rgl","misc3d")
for ( x in mypkg ) 
  {
  install.packages(x)
  }
RSCRIPT
fi 


ANTSRDIR=$RLDIR
cd $ANTSRDIR
echo install ANTsR to $ANTSRDIR 
RHLIB=` R RHOME`/lib
echo R home lib is $RHLIB 
echo  check ${ANTSRDIR}/ANTsR_src/ANTsR
if [[ ! -s ${ANTSRDIR}/ANTsR_src/ANTsR ]] ; then 
  mkdir ANTsR_src
  cd ANTsR_src
  echo clone ANTsR
  git clone http://github.com/stnava/ANTsR.git
fi 
cd  ${ANTSRDIR}/ANTsR_src
echo call R CMD INSTALL now ... 
myrenvstring=`echo R_LIBS_USER=${ANTSRDIR}:${MYRLDIR}:\$\{R_LIBS_USER\} `
echo ${myrenvstring} >> ~/.Renviron
R CMD INSTALL -l $RLDIR  ANTsR
