#!/bin/bash
setup_content=~/bin/qcd
history_dir=$setup_content/history_dir

#判断路径是否存在
isdir(){
	[ $# -eq 0 ] && return
	string="/${1}/p"
	result="`awk '{print $1}' $history_dir | sed -n "$string"`"
	echo $result 
}
usage(){
	echo "qcd(quick cd) version 1.0 command :"
    echo "<qcd -s [position] dir>  add a directory to $history_dir."
    echo "if content = ./, then add current directory to  $history_dir."
    echo "if position is not, default value equal 1."
    echo ""
    echo "<qcd -d [position]> then delete a directory from $history_dir."
    echo "if position is not, default value equal last."
    echo ""    
    echo "<qcd -l [position]> then list directory from $history_dir."
    echo  "if position is not, default value equal 1, else list all directory,
          then choice one position's content and enter it."
    echo ""	  
    echo "<qcd -e [position]> then enter a directory from $history_dir."
    echo "if position is not, default value equal 1."
    echo ""    
    echo "<qcd -c> then clear $history_dir."
    exit 1
}
list(){
	if [ $# -eq 1 ]
	then
		cat $history_dir
	else 
		num=0
		for arg in $*
		do
			string="${arg}p"
			[ $num -gt 0 ] && sed -n "$string" $history_dir
			num=`expr $num + 1`
		done
	fi
	if [ "`cat $history_dir`" ]
	then
		read choice
		[ "$choice" = q -o "$choice" = Q ] && exit 1
		entry $choice
	else
		echo "history dirctoy is empty!"
		exit 1
	fi
}
entry(){
	line=`wc -l $history_dir | awk '{print $1}'`
	echo "change dirctory!"
	if [ $(isdir $1) ]
	then
		string="${1}p"
		dir=`sed -n "$string" $history_dir | awk '{print $2}'` 
		echo "$dir"
		echo "$dir" > /tmp/qcd/qcd_tmp
	else
		echo "dirctory is not useable!"
	fi
}
delete_op(){
	line=`wc -l $history_dir | awk '{print $1}'`
	line=`expr $line - 1`
	if [ $(isdir $1) ]
	then 
		string="${1}d"
		sed -i "$string" $history_dir
		for (( i=$1; i <=$line; i++ ))
		do
			dnum="$i"
			snum=`expr $dnum + 1`
			exchange="s/$snum/$dnum/"
			sed -i "$exchange" $history_dir
		done
	else
		echo "No such dirctory!"
	fi
}
delete(){
	echo "delete the directories form list!"
	if [ $# -eq 1 ]		#如果没有参数，直接打印所有路径
	then
		cat $history_dir
	else 
		num=0
		subtrahend=1
		last=65535
		for arg in $*
		do
			if [ $num -gt 0 ]
			then
			#每次删除一行，那么如果下一次删除序号大于本次，则序号应减小
				if [ $arg -gt $last ]
				then
					arg=`expr $arg - $subtrahend`
					subtrahend=`expr $subtrahend + 1`
				else
					last=$arg
				fi
				delete_op $arg
			fi
			num=`expr $num + 1`
		done
	fi
	cat $history_dir 
}

supplement(){
	#尽可能的覆盖所有可用的路径表达
	echo "supplement history with a new directory!"
	line=`wc -l $history_dir | awk '{print $1}'`
	#如果路径的形式为 ./subdir 首先去掉./ 然后依靠find和pwd结合打印全路径
	enter_dir=""
	name=`echo "$2" | sed -n 's/.\///p'`
	if [ $name ] 
	then
		enter_dir=`find "$(pwd)" . -nowarn -name "$name" | sed -n '1p'`
	fi
	#如果匹配失败则 enter_dir应为空
	if [ ! "$enter_dir" ]
	then
		enter_dir=$2
		[ ! "$2" = "./" ] || enter_dir=`pwd`   
		[ ! "$2" = "." ] || enter_dir=`pwd`
	fi
	
	if [ $2 = ".." ]
	then 
		cd ..
		enter_dir=`pwd`
	fi
	#是否为可用的路径判断
	if [ ! -d $enter_dir ]
	then
		echo "$enter_dir is not a dirctory!"
		exit 1
	fi
	#插入的位置 当文件本身为空时直接加入文件
	#文件且不为空时插入，但如果是最后一行应为追加
	if [ $line -eq 0 ]
	then
		echo "1 $enter_dir" >> $history_dir
		cat $history_dir
		exit 1
	fi
	
	if [ $1 -gt $line ] 
	then
		num=$line
		cmd="${num}a"
	else
		num=$1
		cmd="${num}i"
	fi
	#调整行号
	string="$cmd\\$num $enter_dir"
	sed -i "$string" $history_dir
	for (( i=$num; i <=$line; i++ ))
	do
		dnum="$i"
		snum=`expr $dnum + 1`
		exchange="${snum}s/$dnum /$snum /"
		sed -i "$exchange" $history_dir
	done
	cat $history_dir
}

clear(){
	echo "clear history directory!"
	sed -i 'd' $history_dir
}

if [ $# -eq 0 ]
then 
	usage
	exit 1
fi

case $1 in
-l)	
	list $* ;;
-e) 
	entry $2;;
-d) 
	delete $* ;;
-s) 
	if [ -d $2 ]
	then
		supplement 1 $2
	else
		if [ -d $3 ] && [ $3 ]
		then
			supplement $2 $3
		else
			echo "$3 is not a dirctory!"
		fi
	fi;;
-c) 
	clear;;
*) usage;;
esac

