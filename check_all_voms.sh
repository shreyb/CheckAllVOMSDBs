#!/bin/sh

# Parse opts
if [[ $# = 0 ]] ; then
	echo "Usage:  ./check_all_voms.sh [-u USERNAME] [DN|substr(DN)]"
	exit 0
fi

while [[ $# -gt 0 ]]
do
	key=$1
	case $key in 
		-u)
			USERNAME=$2
			shift 2
			;;
		-r)
			RAW=1
			shift
			;;
		*)
			VISUAL=1
			SEARCHSTRING=$1
			shift
			;;
	esac	
done

# Figure out the search string
if [[ -n $USERNAME ]] ; then
	SEARCHSTRING="%CN=UID:$USERNAME"
else
	SEARCHSTRING="%$SEARCHSTRING%"
fi

# Get list of VOMS DBs
VOMSDBS=`mysql  --defaults-extra-file=/usr/local/bin/gco_random/voms/.secret -e 'show databases;' | grep -G "voms"`

# For each DB, get groups/roles, certs
for DB in ${VOMSDBS};
do 
	echo "VO DATABASE: $DB"
	groups_roles=`mysql --defaults-extra-file=/usr/local/bin/gco_random/voms/.secret -s -N -D $DB -e "SELECT CONCAT(g.dn, ' ', r.role, '@@')  FROM usr AS u JOIN m JOIN groups AS g JOIN roles AS r WHERE u.userid = m.userid AND g.gid = m.gid AND r.rid = m.rid AND u.dn like '$SEARCHSTRING'"`
	certs=`mysql --defaults-extra-file=/usr/local/bin/gco_random/voms/.secret -s -N -D $DB -e "SELECT CONCAT(c.subject_string,'@@') FROM certificate c INNER JOIN usr u on u.userid = c.usr_id WHERE u.dn like '$SEARCHSTRING'"`

	IFS=@@

	if [[ $groups_roles ]]; then
		echo -e "GROUPS AND ROLES"
		echo ${groups_roles[@]}
	else
		echo "No groups and roles registered for this VO"
	fi

	if [[ $certs ]]; then
		echo -e "\nREGISTERED CERTS"
		echo ${certs[@]}
	else
		echo "No certs registered in this VO"
	fi
	echo -e "\n"
done


# Ideas for dev:
# 2.  Have a visual format vs. a script format.  For the visual format, output each VO, and then the list of groups, roles for each one, and then the certs.  For the script format (for parsing by a script), output at each line, the vo, group, role,
# dn, and date added to the certs table. 
# 3.  Have ability to check all DBs for any registered cert, and then pull all the certs registered for that same user
exit 0
