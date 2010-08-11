# Useful functions for working with services and domains.

# The concept of a service is an abstraction used in dCache scripts. A
# service is the type of a domain. A service can have zero or more
# domains. A service corresponds to a job file in the jobs directory.
#
# This script defines functions for mapping services to domains,
# domains to services, starting and stopping domains, etc.
#

# Returns 0 if option is set to 'yes' or 'y' in node_config or
# door_config, 1 otherwise.
isNodeConfigEnabled() # in $1 = option name
{
    local value
    eval value=\"\$NODE_CONFIG_$1\"
    case "$(echo $value | tr '[A-Z]' '[a-z]')" in
        yes|y)
            return 0;
            ;;
        *)
            return 1;
            ;;
    esac
}

# Prints all domains for the given service. Services like 'pool' and
# 'dcap' may have more than one domain. Notice that this function is
# not limitted to configured domains.
printDomains() # in $1 = service
{
    local i
    local door
    local file

    case "$1" in
        dcap)
            for i in ${DCACHE_CONFIG}/door*Setup; do
                door=$(echo $i | sed -e "s#.*door\(.*\)Setup#\1#")
                printf "%s" "dcap${door}-${hostname}Domain "
            done
            ;;

        gPlazma)
            printf "%s" "gPlazma-${hostname}Domain "
            ;;

        xrootd)
            printf "%s" "xrootd-${hostname}Domain "
            ;;

        gridftp)
            for i in ${DCACHE_CONFIG}/gridftpdoor*Setup; do
                door=$(echo $i | sed -e "s#.*gridftpdoor\(.*\)Setup#\1#")
                printf "%s" "gridftp${door}-${hostname}Domain "
            done
            ;;

        weakftp)
            for i in ${DCACHE_CONFIG}/weakftpdoor*Setup; do
                door=$(echo $i | sed -e "s#.*weakftpdoor\(.*\)Setup#\1#")
                printf "%s" "weakftp${door}-${hostname}Domain "
            done
            ;;

        kerberosftp)
            for i in ${DCACHE_CONFIG}/kerberosftpdoor*Setup; do
                door=$(echo $i | sed -e "s#.*kerberosftpdoor\(.*\)Setup#\1#")
                printf "%s" "kerberosftp${door}-${hostname}Domain "
            done
            ;;

        webdav)
            printf "%s" "webdav-${hostname}Domain "
            ;;

        gsidcap)
            for i in ${DCACHE_CONFIG}/gsidcapdoor*Setup; do
                door=$(echo $i | sed -e "s#.*gsidcapdoor\(.*\)Setup#\1#")
                printf "%s" "gsidcap${door}-${hostname}Domain "
            done
            ;;

        kerberosdcap)
            for i in ${DCACHE_CONFIG}/kerberosdcapdoor*Setup; do
                door=$(echo $i | sed -e "s#.*kerberosdcapdoor\(.*\)Setup#\1#")
                printf "%s" "kerberosdcap${door}-${hostname}Domain "
            done
            ;;

        srm)
            printf "%s" "srm-${hostname}Domain "
            ;;

        pool)
            for i in $(printAllPoolDomains); do
                getPoolListFile $i file
                if ! isFileEmpty "$file"; then
                    printf "%s" "$i "
                fi
            done
            ;;

        admin)
            printf "adminDoorDomain "
            ;;

        dir)
            printf "dirDomain "
            ;;

        *Domain)
            printf "%s" "$1 "
            ;;

        *)
            printf "%s" "${1}Domain "
            ;;
    esac
}

# Prints domains used by all node types as defined by legacy
# node_config variables.
printLegacyDomains()
{
    if isNodeConfigEnabled replicaManager; then
        printDomains replica
    fi
    if isNodeConfigEnabled DCAP; then
        printDomains dcap
    fi
    if isNodeConfigEnabled XROOTD; then
        printDomains xrootd
    fi
    if isNodeConfigEnabled GRIDFTP; then
        printDomains gridftp
    fi
    if isNodeConfigEnabled GSIDCAP; then
        printDomains gsidcap
    fi
    if isNodeConfigEnabled SPACEMANAGER; then
        printDomains spacemanager
    fi
    if isNodeConfigEnabled TRANSFERMANAGERS; then
        printDomains transfermanagers
    fi
    if isNodeConfigEnabled SRM; then
        printDomains srm
    fi
}

# Prints domains used by admin and custom nodes as defined by legacy
# node_config variables.
printLegacyAdminDomains()
{
    if isNodeConfigEnabled info; then
        printDomains info
    fi
    if isNodeConfigEnabled statistics; then
        printDomains statistics
    fi
}

# Prints domains used by custom nodes as defined by legacy node_config
# variables.
printLegacyCustomDomains()
{
    if isNodeConfigEnabled lmDomain; then
        printDomains lm
    fi
    if isNodeConfigEnabled poolManager; then
        printDomains dCache
    fi
    if isNodeConfigEnabled dirDomain; then
        printDomains dir
    fi
    if isNodeConfigEnabled adminDoor; then
        printDomains admin
    fi
    if isNodeConfigEnabled httpDomain; then
        printDomains httpd
    fi
    if isNodeConfigEnabled utilityDomain; then
        printDomains utility
    fi
    if isNodeConfigEnabled gPlazmaService; then
        printDomains gPlazma
    fi
    if isNodeConfigEnabled pnfsManager; then
        printNameSpaceDomains
    fi
}

# Prints domain hosting PnfsManager
printNameSpaceDomains()
{
    case "$NODE_CONFIG_NAMESPACE" in
        chimera)
            printDomains chimera
            ;;
        *)
            printDomains pnfs
            ;;
    esac
}

# Prints all configured domains
printAllDomains()
{
    case "$NODE_CONFIG_NODE_TYPE" in
        admin)
            printDomains lm
            printDomains dCache
            printDomains dir
            printDomains admin
            printDomains httpd
            printDomains utility
            printDomains gPlazma
            printNameSpaceDomains
            printDomains pool
            printLegacyAdminDomains
            printLegacyDomains
            ;;

        custom)
            printLegacyCustomDomains
            printDomains pool
            printLegacyAdminDomains
            printLegacyDomains
            ;;
        pool)
            printDomains pool
            printLegacyDomains
            ;;

        door)
            printLegacyDomains
            ;;
    esac

    for service in $NODE_CONFIG_SERVICES; do
        printDomains $service
    done
}

# Prints the list of all configured pool domains, including empty
# domains.
printAllPoolDomains()
{
    if [ -f "${pool_config}/${hostname}.domains" ]; then

        while read domain; do
            if [ ! -f "${pool_config}/${domain}.poollist" ]; then
                printp "Requested pool list file not found (skipped):
                        ${domain}.poollist" 1>&2
            else
                printf "%s" "${domain}Domain "
            fi
        done < "${pool_config}/${hostname}.domains"

    elif [ -f "${pool_config}/${hostname}.poollist" ]; then
        printf "%s" "${hostname}Domain "
    fi
}

# Returns the service name of a domain. The service name corresponds
# to the name of the batch file of that service, without the file
# suffix.
getService() # in $1 = domain name, out $2 = service
{
    local ret
    if contains $1 $(printAllPoolDomains); then
        ret="pool"
    else
        case "$1" in
            dcap*-*Domain)   ret="dcap" ;;
            gPlazma-*Domain) ret="gPlazma" ;;
            xrootd-*Domain)  ret="xrootd" ;;
            gridftp*-*Domain) ret="gridftp" ;;
            weakftp*-*Domain) ret="weakftp" ;;
            kerberosftp*-*Domain) ret="kerberosftp" ;;
            webdav-*Domain)  ret="webdav" ;;
            gsidcap*-*Domain) ret="gsidcap" ;;
            kerberosdcap*-*Domain) ret="kerberosdcap" ;;
            srm-*Domain)     ret="srm" ;;
            adminDoorDomain) ret="admin" ;;
            *Domain)         ret="${1%Domain}" ;;
            *)               return 1 ;;
        esac
    fi
    eval $2=\"$ret\"
}

# Given a list of domains, prints a list of corresponding service
# names.
printServices() # in $* = list of domains
{
    local service
    for domain in $*; do
        getService $domain service
        printf "${service} "
    done
}

# Returns the name of the pool list file for the given pool domain.
getPoolListFile() # in $1 = domain name, out $2 = pool list file
{
    eval $2=\"${pool_config}/${1%Domain}.poollist\"
}

# Returns the setup file path for a service or domain
getConfigurationFile() # in $1 = service or domain, out $2 = configuration file
{
    local filename
    local name
    name="$1"

    case "${name}" in
        srm|srm-*Domain)
            filename="srmSetup"
            ;;
        dcap)
            filename="doorSetup"
            ;;
        dcap*-*Domain)
	    name=${name%%-*Domain}
            filename="door${name#dcap}Setup"
            ;;
        xrootd|xrootd-*Domain)
            filename="xrootdDoorSetup"
            ;;
        weakftp|weakftp*-*Domain)
	    tmp=${name%%-*Domain}
            filename="weakftpdoor${tmp#weakftp}Setup"
            ;;
        kerberosftp|kerberosftp*-*Domain)
	    tmp=${name%%-*Domain}
            filename="kerberosftpdoor${tmp#kerberosftp}Setup"
            ;;
        gridftp|gridftp*-*Domain)
	    tmp=${name%%-*Domain}
            filename="gridftpdoor${tmp#gridftp}Setup"
            ;;
        kerberosdcap|kerberosdcap*-*Domain)
	    tmp=${name%%-*Domain}
            filename="kerberosdcapdoor${tmp#kerberosdcap}Setup"
            ;;
        gsidcap|gsidcap*-*Domain)
	    tmp=${name%%-*Domain}
            filename="gsidcapdoor${tmp#gsidcap}Setup"
            ;;
        admin|adminDoorDomain)
            filename="adminDoorSetup"
            ;;
        gPlazma|gPlazma-*Domain)
            filename="gPlazmaSetup"
            ;;
        webdav|webdav-*Domain)
            filename="webdavSetup"
            ;;
        *Domain)
	    if contains $name $(printAllPoolDomains); then
		filename="poolSetup"
	    else
		filename="${name%Domain}Setup"
	    fi
            ;;
        *)
            filename="${name}Setup"
            ;;
    esac

    if [ -f "${DCACHE_CONFIG}/${filename}" ] ; then
        eval $2=\"${DCACHE_CONFIG}/${filename}\"
    elif [ -f "${DCACHE_CONFIG}/${filename}-$(uname -n)" ] ; then
        eval $2=\"${DCACHE_CONFIG}/${filename}-$(uname -n)\"
    elif [ -f "/etc/${filename}" ] ; then
        eval $2=\"/etc/${filename}\"
    else
        return 1
    fi
}

# Loads a setup into environment variables. All environment variables
# are prefixed by $2 followed by an underscore. Only loads the setup
# file the first time the function is called for a given prefix.
loadConfigurationFile() # in $1 = service or domain, in $2 = prefix
{
    local file
    if eval "[ -z \"\$SETUP_$2\" ]"; then
        getConfigurationFile "$1" file || return
        readconf "$file" "$2_" || return
        eval "SETUP_$2=1"
    fi
}

# Returns configuration value for a service
getConfigurationValue() # in $1 = service or domain, in $2 = key, out $3 = value
{
    local prefix
    prefix=$(echo $1 | sed -e 's/_/__/g' -e 's/-/_/g')
    loadConfigurationFile $1 $prefix && eval $3=\"\${${prefix}_$2}\"
}
