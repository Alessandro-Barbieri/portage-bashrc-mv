#!/bin/bash
# (C) Martin V\"ath <martin@mvath.de>

FlagEval() {
	case ${-} in
	*f*)	eval "${*}";;
	*)	set -f
		eval "${*}"
		set +f;;
	esac
}

FlagAdd() {
	local addres addf addvar
	addvar=${1}
	shift
	eval addres=\${${addvar}}
	for addf
	do	case " ${addres}  " in
		*[[:space:]]"${addf}"[[:space:]]*)
			continue;;
		esac
		addres=${addres}${addres:+ }${addf}
	done
	eval ${addvar}=\${addres}
}

FlagSub() {
	local subres subpat subf subvar sublist
	subvar=${1}
	shift
	subres=
	eval sublist=\${${subvar}}
	for subf in ${sublist}
	do	for subpat
		do	[ -n "${subpat:++}" ] || continue
			case ${subf} in
			${subpat})
				subf=
				break;;
			esac
		done
		[ -z "${subf:++}" ] || subres=${subres}${subres:+ }${subf}
	done
	eval ${subvar}=\${subres}
}

FlagReplace() {
	local repres repf repcurr repvar reppat repfound
	repvar=${1}
	shift
	eval repf=\${${repvar}}
	reppat=${1}
	shift
	if [ -z "${repf:++}" ]
	then	eval ${repvar}=\${*}
		return
	fi
	repres=
	repfound=:
	for repcurr in ${repf}
	do	case ${repcurr} in
		${reppat})
			${repfound} && FlagAdd repres "${@}"
			repfound=false
			continue;;
		esac
		repres=${repres}${repres:+ }${repcurr}
	done
	${repfound} && FlagAdd repres "${@}"
	eval ${repvar}=\${repres}
}

FlagSet() {
	local setvar
	setvar=${1}
	shift
	eval ${setvar}=\${*}
}

FlagAddCFlags() {
	FlagAdd CFLAGS "${@}"
	FlagAdd CXXFLAGS "${@}"
}

FlagSubCFlags() {
	FlagSub CFLAGS "${@}"
	FlagSub CXXFLAGS "${@}"
	FlagSub CPPFLAGS "${@}"
	FlagSub OPTCFLAGS "${@}"
	FlagSub OPTCXXFLAGS "${@}"
	FlagSub OPTCPPFLAGS "${@}"
}

FlagReplaceCFlags() {
	FlagReplace CFLAGS "${@}"
	FlagReplace CXXFLAGS "${@}"
	FlagReplace CPPFLAGS "${@}"
	FlagSub OPTCFLAGS "${1}"
	FlagSub OPTCXXFLAGS "${1}"
	FlagSub OPTCPPFLAGS "${1}"
}

FlagSetallcflags() {
	FlagSet CFLAGS "${@}"
	CXXFLAGS=${CFLAGS}
	CPPFLAGS=
	OPTCFLAGS=
	OPTCXXFLAGS=
	OPTCPPFLAGS=
}

FlagAddAllFlags() {
	FlagAddCFlags "${@}"
}

FlagSubAllFlags() {
	FlagSubCFlags "${@}"
	FlagSub LDFLAGS "${@}"
	FlagSub OPTLDFLAGS "${@}"
}

FlagReplaceAllFlags() {
	FlagReplaceCFlags "${@}"
	FlagSub LDFLAGS "${1}"
	FlagSub OPTLDFLAGS "${1}"
}

FlagSetAllFlags() {
	FlagSetallcflags "${@}"
	LDFLAGS=
	OPTLDFLAGS=
}

FlagAthlon() {
	FlagSubCFlags -march='*'
	FlagAddCFlags -march=athlon-4
	command -v x86_64-pc-linux-gnu-gcc32 >/dev/null 2>&1 && \
		export CC=x86_64-pc-linux-gnu-gcc32
	command -v x86_64-pc-linux-gnu-g++32 >/dev/null 2>&1 && \
		export CXX=x86_64-pc-linux-gnu-g++32
}

FlagExecute() {
	local ex exy excurr
	for excurr
	do	case ${excurr} in
		'#'*)
			return;;
		'!'*)
			[ "${HOSTTYPE}" = 'i686' ] || continue
			ex=${excurr#?};;
		'~'*)
			[ "${HOSTTYPE}" = 'x86_64' ] || continue
			ex=${excurr#?};;
		*)
			ex=${excurr};;
		esac
		case ${ex} in
		/*/*)
			ex=${ex%/}
			ex=${ex#/}
			FlagEval FlagReplaceAllFlags "${ex%%/*}" "${ex#*/}";;
		'-'*)
			FlagAddAllFlags "${ex}";;
		'+'*)
			FlagSubAllFlags "-${ex#+}";;
		'C*FLAGS-='*)
			FlagEval FlagSubCFlags ${ex#*-=};;
		'C*FLAGS+='*)
			FlagEval FlagAddCFlags ${ex#*+=};;
		'C*FLAGS='*)
			FlagEval FlagSetallcflags "${ex#*=}";;
		'C*FLAGS/=/'*/*)
			ex=${ex%/}
			ex=${ex#*/=/}
			FlagEval FlagReplaceCFlags "${ex%%/*}" "${ex#*/}";;
		'*FLAGS-='*)
			FlagEval FlagSubAllFlags ${ex#*-=};;
		'*FLAGS+='*)
			FlagEval FlagAddAllFlags ${ex#*+=};;
		'*FLAGS='*)
			FlagEval FlagSetAllFlags "${ex#*=}";;
		'*FLAGS/=/'*/*)
			ex=${ex%/}
			ex=${ex#*/=/}
			FlagEval FlagReplaceAllFlags "${ex%%/*}" "${ex#*/}";;
		'ATHLON32')
			FlagAthlon;;
		'NOC*OPT='*|'NOC*='*)
			FlagEval FlagSet NOCOPT "${ex#*=}"
			NOCXXOPT=${NOCOPT}
			NOCPPOPT=${NOCOPT};;
		'NO*OPT='*)
			FlagEval FlagSet NOCOPT "${ex#*=}"
			NOCXXOPT=${NOCOPT}
			NOCPPOPT=${NOCOPT}
			NOLDOPT=${NOCOPT};;
		'NOLD*='*)
			FlagEval FlagSet NOLDOPT "${ex#*=}"
			NOLDADD=${NOLDOPT};;
		'NO*'*)
			FlagEval FlagSet NOCOPT "${ex#*=}"
			NOCXXOPT=${NOCOPT}
			NOCPPOPT=${NOCOPT}
			NOLDOPT=${NOCOPT}
			NOLDADD=${NOCOPT}
			NOFFLAGS=${NOCOPT}
			NOFCFLAGS=${NOCOPT};;
		'SAFE')
			NOCOPT=1
			NOCXXOPT=1
			NOCPPOPT=1
			NOLDOPT=1
			NOLDADD=1
			NOCADD=1
			LDFLAGS=
			CONFIG_SITE=
			NOLAFILEREMOVE=1;;
		*' '*'='*)
			FlagEval "${ex}";;
		*'/=/'*'/'*)
			ex=${ex%/}
			exy=${ex#*/=/}
			FlagEval FlagReplace "${ex%%/=/*}" "${exy%%/*}" "${exy#*/}";;
		*'-='*)
			FlagEval FlagSub "${ex%%-=*}" ${ex#*-=};;
		*'+='*)
			FlagEval FlagAdd "${ex%%+=*}" ${ex#*+=};;
		*'='*)
			FlagEval FlagSet "${ex%%=*}" "${ex#*=}";;
		*)
			FlagEval "${ex}";;
		esac
	done
}

FlagMask() {
	if command -v masked-packages >/dev/null 2>&1
	then
FlagMask() {
	masked-packages -qm "${1}" -- "${CATEGORY}/${PF}:${SLOT}"${PORTAGE_REPO_NAME:+::}${PORTAGE_REPO_NAME}
}
	else
FlagMask() {
	local add=
	case ${1%::*} in
	*':'*)	add=":${SLOT}";;
	esac
	case ${1} in
	*'::'*)	add="${add}::${PORTAGE_REPO_NAME}";;
	esac
	case ${1} in
	'~'*)
		case "~${CATEGORY}/${PN}-${PV}${add}" in
		${1})	return;;
		esac;;
	'='*)
		case "=${CATEGORY}/${PF}${add}" in
		${1})	return;;
		esac;;
	*)
		case "${CATEGORY}/${PN}${add}" in
		${1})	return;;
		esac;;
	esac
	return 1
}
	fi
	FlagMask
}

FlagScanLine() {
	local match
	[ ${#} -lt 2 ] && return
	case ${1:-#} in
	'#'*)	return 0;
	esac
	FlagMask "${1}" || return 0
	match=${1}
	shift
	BashrcdEcho "${scanfile} -> ${match}: ${*}"
	FlagExecute "${@}"
}

FlagScanFiles() {
	local scanfile scanl oldifs
	for scanfile
	do	[ -z "${scanfile:++}" ] && continue
		test -r "${scanfile}" || continue
		while IFS= read -r scanl
		do	FlagEval FlagScanLine "${scanl}"
		done <"${scanfile}"
	done
}

FlagScanDir() {
	local scantmp scanifs scanfile
	scanifs=${IFS}
	if test -d "${1}"
	then	IFS='
'
		for scantmp in `find -L "${1}" \
		'(' '(' -name '.*' -o -name '*~' ')' -prune ')' -o \
			-type f -print`
		do	IFS=${scanifs}
			FlagScanFiles "${scantmp}"
		done
	else	FlagScanFiles "${1}"
	fi
	scanfile='FLAG_ADDLINES'
	IFS='
'
	for scantmp in ${FLAG_ADDLINES}
	do	IFS=${scanifs}
		FlagEval FlagScanLine "${scantmp}"
	done
	IFS=${scanifs}
}

FlagSetUseNonGNU() {
	[ -n "${CC}${CXX}" ] && return
	case " ${IUSE} " in
	*" clang "*)
		use clang
		return;;
	esac
	return 1
}

FlagSetNonGNU() {
	: ${NOLDADD:=1}
	FlagSubAllFlags '-fno-ident' '-fweb' '-frename-registers' \
		'-fpredictive-commoning' '-fdirectives*' \
		'-funsafe-loop*' '-ftree-vectorize*' '-fgcse*' '-ftree*' \
		'-fnothrow-opt' '-fno-enforce-eh-specs' \
		'-fgraphite*' '-floop*' \
		'-flto-*' '-fuse-linker-plugin' '-fwhole-program'
}

FlagSetFlags() {
	local ld i
	ld=
	: ${GPO_PARENT:=/var/cache/gpo}
	: ${GPO_DIR:="${GPO_PARENT}/${CATEGORY}:${P}"}
	FlagScanDir "${CONFIG_ROOT%/}/etc/portage/package.cflags"
	[ -z "${USE_NONGNU++}" ] && FlagSetUseNonGNU && USE_NONGNU=1
	BashrcdTrue ${USE_NONGNU} && FlagSetNonGNU
	if [ -n "${FLAG_ADD}" ]
	then	BashrcdEcho "FLAG_ADD: ${FLAG_ADD}"
		FlagEval FlagExecute "${FLAG_ADD}"
	fi
	GPO_DIR=${GPO_DIR%/}
	case ${GPO_DIR:-/} in
	/)	error 'GPO_DIR must not be empty'
		false;;
	/*)	:;;
	*)	error 'GPO_DIR must be an absolute path'
		false;;
	esac || {
		die 'Bad GPO_DIR'
		exit 2
	}
	if BashrcdTrue ${GPO}
	then	FlagAddCFlags "-fprofile-generate=${GPO_DIR}" \
			-fvpt -fprofile-arcs
		FlagAdd LDFLAGS -fprofile-arcs
	elif ! BashrcdTrue ${NOGPO} && test -r "${GPO_DIR}"
	then	use_gpo=:
		: ${KEEPGPO:=:}
		FlagAddCFlags "-fprofile-use=${GPO_DIR}" \
			-fvpt -fbranch-probabilities -fprofile-correction
	fi
	BashrcdTrue ${NOLDOPT} || FlagAdd LDFLAGS ${OPTLDFLAGS}
	BashrcdTrue ${NOCADD} || case " ${LDFLAGS}" in
		*[[:space:]]'-flto'*)
			ld="${CFLAGS} ${CXXFLAGS}";;
		esac
	BashrcdTrue ${NOLDADD} || FlagAddCFlags ${LDFLAGS}
	FlagAdd ldadd ${ld}
	BashrcdTrue ${NOCOPT} || FlagAdd CFLAGS ${OPTCFLAGS}
	BashrcdTrue ${NOCXXOPT} || FlagAdd CXXFLAGS ${OPTCXXFLAGS}
	BashrcdTrue ${NOCPPOPT} || FlagAdd CPPFLAGS ${OPTCPPFLAGS}
	BashrcdTrue ${NOFFLAGS} || FFLAGS=${CFLAGS}
	BashrcdTrue ${NOFCFLAGS} || FCFLAGS=${FFLAGS}
	BashrcdTrue ${NOFILTER_CFLAGS} || FlagSub CFLAGS \
		-fvisibility-inlines-hidden \
		-fno-enforce-eh-specs
	BashrcdTrue ${NOFILTER_FFLAGS} || FlagSub FFLAGS \
		-fdirectives-only \
		-fvisibility-inlines-hidden \
		-fno-enforce-eh-specs
	BashrcdTrue ${NOFILTER_FCFLAGS} || FlagSub FCFLAGS \
		-fdirectives-only \
		-fvisibility-inlines-hidden \
		-fno-enforce-eh-specs
	unset OPTCFLAGS OPTCXXFLAGS OPTCPPFLAGS OPTLDFLAGS
	unset NOLDOPT NOLDADD NOCOPT NOCXXOPT NOFFLAGS NOFCFLAGS
	unset NOFILTER_CFLAGS NOFILTER_FFLAGS NOFILTER_FCFLAGS
}

FlagInfoExport() {
	local out
	for out in FEATURES CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS LDFLAGS \
		MAKEOPTS EXTRA_ECONF EXTRA_EMAKE USE_NONGNU
	do	eval "if [ -n \"\${${out}:++}\" ]
		then	export ${out}
			BashrcdEcho \"${out}='\${${out}}'\"
		else	unset ${out}
		fi"
	done
	if BashrcdTrue ${GPO}
	then	BashrcdEcho "Create GPO into ${GPO_DIR}"
	elif ${use_gpo}
	then	BashrcdEcho "Using GPO from ${GPO_DIR}"
	fi
	out=`gcc --version | head -n 1` || out=
	BashrcdEcho "${out:-cannot determine gcc version}"
	BashrcdEcho "`uname -a`"
}

FlagCompile() {
	eerror \
"${CONFIG_ROOT%/}/etc/portage/bashrc.d/*flag.sh strange order of EBUILD_PHASE:"
	die "compile or preinst before setup"
	exit 2
}

FlagPreinst() {
	FlagCompile
}

FlagSetup() {
FlagCompile() {
:
}
	local use_gpo=false
	FlagSetFlags
	if BashrcdTrue ${GPO}
	then
FlagPreinst() {
	test -d "${GPO_DIR}" || mkdir -p -m +1777 -- "${GPO_DIR}" || {
		eerror "cannot create gpo directory ${GPO_DIR}"
		die 'cannot create GPO_DIR'
		exit 2
	}
}
	elif BashrcdTrue ${KEEPGPO}
	then
FlagPreinst() {
:
}
	else
FlagPreinst() {
	test -d "${GPO_DIR}" || return 0
	BashrcdEcho "removing gpo directory ${GPO_DIR}"
	rm -r -f -- "${GPO_DIR}" || {
		eerror "cannot remove gpo directory ${GPO_DIR}"
		die 'cannot remove GPO_DIR'
		exit 2
	}
	local g
	g=${GPO_DIR%/*}
	[ -z "${g}" ] || rmdir -p -- "${g}" >/dev/null 2>&1
}
	fi
	FlagInfoExport
}

BashrcdPhase compile FlagCompile
BashrcdPhase preinst FlagPreinst
BashrcdPhase setup FlagSetup
