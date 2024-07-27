#!/bin/bash

# 遇到错误即终止
set -e

#

# 日志
function Libscc_Log_PrintLine() {
    if [ "$1" = "debug" ]; then
        printf "\e[1m\e[37m * debug: \e[0m$2\n"
    elif [ "$1" = "info" ]; then
        printf "\e[1m\e[32m * info: \e[0m$2\n"
    elif [ "$1" = "warning" ]; then
        printf "\e[1m\e[33m * warning: \e[0m$2\n"
    elif [ "$1" = "error" ]; then
        printf "\e[1m\e[91m * error: \e[0m$2\n"
    elif [ "$1" = "fafal" ]; then
        printf "\e[1m\e[31m * fafal: \e[0m$2\n"
    fi
    eval let ${1}Number_$$+=1
}

# 初始化日志变量
function Libscc_Log_Initialize() {
    eval export debugNumber_$$=0
    eval export infoNumber_$$=0
    eval export warningNumber_$$=0
    eval export errorNumber_$$=0
    eval export fafalNumber_$$=0
}

# 获取日志信息
function Libscc_Log_Get(){
    eval echo "\${debugNumber_$$} debugs, \${infoNumber_$$} infos, \${warningNumber_$$} warnings, \${errorNumber_$$} errors and \${fafalNumber_$$} fafals generated"
}

# 对文件`$1'替换字符串`$2'为`$3'
function Libscc_Text_Replace() {
    sed -i '' "s/$2/$3/g" "$1"
}

# 对文件`$1'删除空白行
function Libssc_Text_RemoveBlankLines() {
    sed  -i '' '/^$/d' "$1"
}

# 对文件`$1'删除所有开头为`$2'的行
function Libssc_Text_RemoveLinesStartingWith() {
    sed -i '' "/^$2/"d "$1"
}

# 对文件`$1'在字符串`$2'前加字符串`$3'
function Libscc_Text_AddBefore() {
    sed -i '' "s/^$2/$3&/" "$1"
}

# 对文件`$1'在字符串`$2'后加字符串`$3'
function Libscc_Text_AddAfter() {
    sed -i '' "s/^$2/&$3/" "$1"
}

# 对文件`$1'分别在字符串`$2'前、后加字符串`$3'`$4'
function Libscc_Text_AddBeforeAfter() {
    sed -i '' "s/^$2/$3&/;s/^$2/&$4/" "$1"
}

# 对文件`$1'获取行数
function Libscc_Text_GetLineNumber() {
    wc -l < "$1"
}

# 对文件`$1'获取第`$2'行
function Libscc_Text_GetLine () {
    sed -n "${2}p" "${1}"
}

# 对文件`$1'获取`$2'所在行
function Libscc_Text_GetStringLocationLine () {
    sed -n "/$2/=" "$1"
}

# 对字符串`$1'获取字符串`$2'个数
function Libscc_String_GetStringNumber() {
    echo "$1" | grep -o "$2" | wc -l
}

# 对字符串`$1'获取长度
function Libscc_String_GetStringLength() {
    echo "$1" | wc -L
}

# 报错：丢失终止字符或括号`$1'
function Libscc_Log_MissingTerminatingCharacter() {
    Libscc_Log_PrintLine error "missing terminating $1 character"
    printf " ${i}\t\b\b| "
    eval echo -n \$'{'currentLine_$$'}'
    echo ""
    # 8个占位符至内容
    for ((j=$(Libscc_String_GetStringLength "$(eval echo \${currentLine_$$})"); j>=1; j--)); do
        # `$j'代表当前栏数
        # `$(Libscc_String_GetStringLength "$(eval echo \${currentLine_$$})")'代表总栏数
        if [ "$(eval echo \${currentLine_$$: ${j}: 1})" = "$1" ]; then
            printf "      | "
            for ((k=1; k<=$j; k++)); do
                echo -n " "
            done
            printf "\e[91m^\e[0m"
            if [ $k -lt "$(Libscc_String_GetStringLength "$(eval echo \${currentLine_$$})")" ]; then # 如果当前栏数小于总栏数
                for ((l=$k; l<$(Libscc_String_GetStringLength "$(eval echo \${currentLine_$$})"); l++)); do
                    printf "\e[91m~\e[0m"
                done
            fi
            echo
            break
        fi
    done
}

# 检查是否丢失终止字符
function Libscc_String_CheckClosedSymbols() {
    for ((i=1; i<=$(eval echo \${sourceFileLineNumber_$$}); i++)); do
            #echo -n " >>> LINE $i >>> " && eval echo \${currentLine_$$}
        eval export currentLine_$$='$(Libscc_Text_GetLine "$1" $i)' # 使用`$(eval echo \${currentLine_$$})'作为第`$i'行内容
        eval export currentLineClosedSymbolNumber_$$="$(Libscc_String_GetStringNumber "$(eval echo \${currentLine_$$})" "$2")"
            #eval echo \${currentLineClosedSymbolNumber_$$}
        eval export currentLineBackSlashClosedSymbolNumber_$$="$(Libscc_String_GetStringNumber "$(eval echo \${currentLine_$$})" "\\\\$2")"
            #eval echo \${currentLineBackSlashClosedSymbolNumber_$$}
        eval export currentLineLiteralClosedSymbolNumber_$$="$(($(eval echo \${currentLineClosedSymbolNumber_$$}) - $(eval echo \${currentLineBackSlashClosedSymbolNumber_$$})))"
            #eval echo \${currentLineLiteralClosedSymbolNumber_$$}
        if [ $(($(eval echo \${currentLineLiteralClosedSymbolNumber_$$}) % 2)) -eq 1 ]; then
            Libscc_Log_MissingTerminatingCharacter "$2"
            Libscc_Log_Get
            exit 1
        fi
    done
}

# 检查是否丢失括号
function Libscc_String_CheckBrackets() {
    for ((i=1; i<=$(eval echo \${sourceFileLineNumber_$$}); i++)); do
        eval export currentLine_$$='$(Libscc_Text_GetLine "$1" $i)' # 使用`$(eval echo \${currentLine_$$})'作为第`$i'行内容
        eval export currentLineBracketsLeft_$$="$(Libscc_String_GetStringNumber "$(eval echo \${currentLine_$$})" "\\$2")"
        eval export currentLineBracketsRight_$$="$(Libscc_String_GetStringNumber "$(eval echo \${currentLine_$$})" "\\$3")"
        eval export currentLineBackSlashBracketsLeft_$$="$(Libscc_String_GetStringNumber "$(eval echo \${currentLine_$$})" "\\\\\\$2")"
        eval export currentLineBackSlashBracketsRight_$$="$(Libscc_String_GetStringNumber "$(eval echo \${currentLine_$$})" "\\\\\\$3")"
        eval export currentLineLiteralBracketsLeft_$$="$(($(eval echo \${currentLineBracketsLeft_$$}) - $(eval echo \${currentLineBackSlashBracketsLeft_$$})))"
        eval export currentLineLiteralBracketsRight_$$="$(($(eval echo \${currentLineBracketsRight_$$}) - $(eval echo \${currentLineBackSlashBracketsRight_$$})))"
        if [ $(eval echo \${currentLineLiteralBracketsLeft_$$}) != $(eval echo \${currentLineLiteralBracketsRight_$$}) ]; then
            Libscc_Log_MissingTerminatingCharacter "$3"
            Libscc_Log_Get
            exit 1
        fi
    done
}
#

Libscc_Log_Initialize

# 检查`$1'是否不为空
if [ -z "$1" ]; then
    Libscc_Log_PrintLine error "no input file"
        #eval echo "\${debugNumber_$$} debugs, \${infoNumber_$$} infos, \${warningNumber_$$} warnings, \${errorNumber_$$} errors and \${fafalNumber_$$} fafals generated"
    Libscc_Log_Get
    exit 1
fi

# 检查文件`$1'是否存在
if [ ! -f "$1" ]; then
    Libscc_Log_PrintLine error "cannot find file: \`$1'"
    Libscc_Log_Get
    exit 1
fi

# 检查文件`$1'后缀名是否为`.shpp.sh'
if [ "${1: -8}" != ".shpp.sh" ]; then
    Libscc_Log_PrintLine error "unknown file type in \`$1'"
    Libscc_Log_PrintLine error "have you named the file as \`*.shpp.sh'?"
    Libscc_Log_Get
    exit 1
fi

# 检查文件`$1'是否可读
if [ ! -r "$1" ]; then
    Libscc_Log_PrintLine error "permission denied"
    Libscc_Log_Get
    exit 1
fi

#

# 初始化变量“源文件”“源文件文件行数”
eval export sourceFile_$$="$1"
eval export sourceFileLineNumber_$$="$(eval Libscc_Text_GetLineNumber "\${sourceFile_$$}")"

# 检查“中间产物文件”解释器是否为`/bin/bash'
    #eval echo \${sourceFile_$$}
    #eval Libscc_Text_GetLine \${sourceFile_$$} 1
if [ "$(eval eval Libscc_Text_GetLine '\${sourceFile_$$}' 1)" != "#!/bin/bash" ]; then
    Libscc_Log_PrintLine error "interpreter is not \`/bin/bash'"
    Libscc_Log_PrintLine error "have you position \`#!/bin/bash' on line 1?"
    Libscc_Log_Get
    exit 1
fi

# 对“中间产物文件”每一行执行检查操作
for i in \" \' \`; do
    Libscc_String_CheckClosedSymbols "$1" $i
done

#

# 删除文件`$1'的后缀名`.shpp.sh'
eval cp "$1" "${1%.shpp.sh}"

# 初始化变量“中间产物”“中间产物文件行数”
eval export objectiveFile_$$="${1%.shpp.sh}"
eval export objectiveFileLineNumber_$$="$(eval Libscc_Text_GetLineNumber "\${objectiveFile_$$}")"

# 对“中间产物文件”每一行执行编译操作
for ((i=1; i<=$(Libscc_Text_GetLineNumber $1); i++)); do
    eval export currentLine_$$='$(Libscc_Text_GetLine "$1" $i)' # 使用`$(eval echo \${currentLine_$$})'作为第`$i'行内容
        #eval echo \${currentLine_$$}
    if [ "$(eval echo \${currentLine_$$})" = "##include {" ]; then
        for ((j=$i; j<=$(Libscc_Text_GetLineNumber $1); j++)); do
            eval export currentLine_$$='$(Libscc_Text_GetLine "$1" $j)' # 使用`$(eval echo \${currentLine_$$})'作为第`$j'行内容
            if [ "$(eval echo \${currentLine_$$})" = "##include {" ]; then
                for ((k=i+1; k<=j-1; k++)); do
                    eval export currentLine_$$='$(Libscc_Text_GetLine "$1" $k)' # 使用`$(eval echo \${currentLine_$$})'作为第`$k'行内容
                    if [ "\${currentLine_$$: 1: 7}" = "source " ];then
                        a
                    fi
                done
                break
            fi
        done
        break
    fi
done