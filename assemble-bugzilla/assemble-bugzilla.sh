#!/usr/bin/bash -e

current_directory=`pwd`
config="${HOME}/abz.rc"

. "${config}"

if [ -z "${repo_dir}" ]
then
    echo "repo_dir variable not set"
    exit 1
fi

if [ -z "${www}" ]
then
    echo "www variable not set"
    exit 1
fi

if [ -z "${remote_repo_upstream}" ]
then
    echo "remote_repo_upstream variable not set"
    exit 1
fi

if [ -z "${remote_repo_customizations}" ]
then
    echo "remote_repo_customizations variable not set"
    exit 1
fi

if [ -z "${bugzilla_files}" ]
then
    echo "bugzilla_files variable not set"
    exit 1
fi

upstream_last_branch="${repo_dir}/upstream-last-branch"
customizations_last_branch="${repo_dir}/customizations-last-branch"
upstream_branch=''
customizations_branch=''

while [ -n "${1}" ]
do
    case "${1}" in
	'-u')
	    if [ -n "${upstream_branch}" ]
	    then
		echo 'Multiple -u parameters are not allowed'
		exit 1
	    fi
	    shift
	    upstream_branch="${1}"
	    shift
	    ;;
	'-c')
	    if [ -n "${customizations_branch}" ]
	    then
		echo 'Multiple -c parameters are not allowed'
		exit 1
	    fi
	    shift
	    customizations_branch="${1}"
	    shift
	    ;;
	*)
	    echo "Unknown parameter: ${1}"
	    exit 1
	    ;;
    esac
done

if [ -z "${upstream_branch}" ]
then
    if [ ! -f "${upstream_last_branch}" ]
    then
	echo "Assembling for the first time. Pass -u parameter with branch name for upstream repo"
	exit 1
    fi
    upstream_branch=`cat "${upstream_last_branch}"`
fi

if [ -z "${customizations_branch}" ]
then
    if [ ! -f "${customizations_last_branch}" ]
    then
	echo "Assembling for the first time. Pass -c parameter with branch name for customizations repo"
	exit 1
    fi
    customizations_branch=`cat "${customizations_last_branch}"`
fi

bgo_upstream='bugzilla-gnome-org-upstream'
bgo_customizations='bugzilla-gnome-org-customizations'
repo_dir_upstream="${repo_dir}/${bgo_upstream}"
repo_dir_customizations="${repo_dir}/${bgo_customizations}"

if [ -d "${repo_dir}" ]
then
    cd "${repo_dir_upstream}"
    git fetch origin
    git branch -D "${upstream_branch}"
    git checkout "${upstream_branch}"
    cd "${repo_dir_customizations}"
    git fetch origin
    git branch -D "${upstream_branch}"
    git checkout "${customizations_branch}"
else
    mkdir -p "${HOME}/repo"

    git clone "${remote_repo_upstream}" "${repo_dir_upstream}"
    cd "${repo_dir_upstream}"
    git checkout "${upstream_branch}"

    git clone "${remote_repo_customizations}" "${repo_dir_customizations}"
    cd "${repo_dir_customizations}"
    git checkout "${customizations_branch}"
fi

if [ ! -f "${upstream_last_branch}" ]
then
    echo 'none' >"${upstream_last_branch}"
fi
old_upstream_branch=`cat "${upstream_last_branch}"`
echo "${upstream_branch}" >"${upstream_last_branch}"

if [ ! -f "${customizations_last_branch}" ]
then
    echo 'none' >"${customizations_last_branch}"
fi
old_customizations_branch=`cat "${customizations_last_branch}"`
echo "${customizations_branch}" >"${customizations_last_branch}"

recreate_dir='no'

if [ "${upstream_branch}" != "${old_upstream_branch}" -o "${customizations_branch}" != "${old_customizations_branch}" ]
then
    recreate_dir='yes'
fi

if [ "${recreate_dir}" = 'yes' ]
then
    if [ -f "${www}/localconfig" -a -f "${www}/answers" -a -d "${www}/data" ]
    then
	rm -rf "${bugzilla_files}"
	mkdir -p "${bugzilla_files}"
	cp -r "${www}"/{localconfig,answers,data} "${bugzilla_files}"
    fi
    rm -rf "${www}"
fi

cp -r "${repo_dir_upstream}" "${www}"
rm -rf "${www}/.git"
cp -r "${repo_dir_customizations}"/* "${www}"
rm -rf "${www}/.git"

if [ "${recreate_dir}" = 'yes' ]
then
    cp -r "${bugzilla_files}"/{localconfig,answers,data} "${www}"
fi

cd "${www}"
./checksetup.pl --verbose answers
cd "${current_directory}"
echo 'bugzilla assemble done'
