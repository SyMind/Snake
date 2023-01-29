#!/bin/bash

# 绘制游戏欢迎界面边框
DisFrame() {
	stop=false
	trap "stop=true" 10
	while ! $stop;do 
		for ((i=1;i<=cols;i++));do 
			printf "\033[1;${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=2;i<=lines;i++));do 
			printf "\033[${i};${cols}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=cols-1;i>=1;i--));do 
			printf "\033[${lines};${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=lines-1;i>=2;i--));do 
			printf "\033[${i};1H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=2;i<=cols-1;i++));do 
			printf "\033[2;${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=2;i<=lines-1;i++));do 
			printf "\033[${i};$[cols-1]H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=cols-2;i>=2; i--));do 
			printf "\033[$[lines-1];${i}H\033[4$((RANDOM%6+1))m \033[0m"
		done
		for ((i=lines-2;i>=2;i--));do 
			printf "\033[${i};2H\033[4$((RANDOM%6+1))m \033[0m"
		done
		sleep 0.1
	done
}

cols=`tput cols`
lines=`tput lines`
clear

DisFrame &
DisFramePid=$!

a=' &&&&  &    &&     &     &   & &&&&&&      &&&      &         &     &     &&&&&&'
b='&      &   & &    & &    & &   &         &         & &       & &   & &    &     '
c=' &&&&  &  &  &   &&&&&   &&    &&&&&&   &   &&&   &&&&&     &   & &   &   &&&&&&'
d='     & & &   &  &     &  & &   &         &    &  &     &   &     &     &  &     '
e='&&&&&  &&    & &       & &   & &&&&&&      &&&& &       & &             & &&&&&&'

abcde=(a b c d e)
for ((i=0;i<5;i++));do
	eval printf "\"\033[$(($[lines/2-6]+$i));$[cols/2-41]H\033[1;5;32m\$${abcde[i]}\033[0m\""
	sleep 0.1
done

i=1
col=$[cols/2-17]
while [[ $i -le 35 ]];do
	printf "\033[$[lines/2+1];${col}H\033[45m \e[0m"
	printf "\033[$[lines/2+3];${col}H\033[45m \e[0m"
	sleep 0
	(( i+=1 ))
	(( col+=1 ))
done

strings="Made by SyMind"
col=$[cols/2-6]
for ((a=0;a<=${#strings}-1;a++));do
	for ((i=$[cols-2]; i>=$col; i--));do
		printf "\033[$[lines/2+2];${i}H\033[1;33m${strings:a:1} \033[0m"
		[[ $i -ne $col ]] && printf "\033[$[lines/2+2];${i}H\033[1;$33m \033[0m"
	done	
	let col++
done

while true;do
	echo "ynq" | grep -q ${ch:-H} && {
		kill -10 ${DisFramePid} &>/dev/null
		break
	}
	printf "\033[$[lines/2+5];$[cols/2-10]H\033[1;31mAre You Ready ? [Y/N]"
	read -s -n 1 ch
	ch=$(echo ${ch} | tr 'A-Z' 'a-z')
done

if [ $ch != 'y' ];then
	{ clear; exit; }
fi
sleep 0.1

# 游戏背景颜色
background_color=40

boundary_u=2
boundary_d=26
boundary_l=2
boundary_r=80
boundary_color=45
smallboundary_color=34
boundary_inner_u=3
boundary_inner_d=25
boundary_inner_l=4
boundary_inner_r=78

food_x=
food_y=

# 默认蛇头的移动方向向右
direction="down"
pre_last_position_x=28
pre_last_position_y=10
position_x=30
position_y=10
head_color=41
body_color=42
key=""
# 游戏速度
game_speed=2
# 游戏得分
game_score=3

# 初始蛇的像素信息
snake_array=(
	$position_x $position_y
	$((position_x-2)) $position_y
	$((position_x-4)) $position_y
	$((position_x-6)) $position_y
)
snake_len=${#snake_array[@]}

# 蛇可活动区域宽度和高度
width=$((boundary_inner_r-boundary_inner_l))
height=$((boundary_inner_d-boundary_inner_u))

# 画方块，为蛇的组成元素
# 方块的高为1，宽为2
# 参数列表：纵向坐标，横向坐标，颜色
drawBlock() {
	printf "\033[$1;$2H\033[$3m \033[0m"
	printf "\033[$1;$(($2+1))H\033[$3m \033[0m"
}

# 获取食物
getFood() {
	isValid=false
	while ! $isValid;do
		food_x=$((RANDOM%width+boundary_inner_l))
		if ((food_x%2==1));then
			food_x=$((food_x+1))
		fi
		food_y=$((RANDOM%height+boundary_inner_u))
		for ((i=0;i<snake_len;i=i+2));do
			if ((snake_array[i]==food_x&&snake_array[i+1]==food_y));then
				isValid=false
			else
				isValid=true
			fi
		done
		if ((isValid==true));then
			drawBlock $food_y $food_x 44
			break
		fi
	done
}

# 游戏的边界
drawBoundary() {
	for ((i=boundary_l;i<=boundary_r;i++));do
		drawBlock $boundary_u $i $boundary_color
		drawBlock $boundary_d $i $boundary_color
	done
	for ((i=boundary_u+1;i<boundary_d;i++));do
		drawBlock $i $boundary_l $boundary_color
		drawBlock $i $boundary_r $boundary_color
	done
	sleep 0.1
}

# 游戏控制，包括对游戏速度的控制
controlGame() {
	# 阻止回调
	stty -echo
	speed=$(printf "%.5f" `echo "scale=5;1/$game_speed"|bc`)
	error=$(read -t $speed -s -n 1 key 2>&1)
	# 低版本 bash read 命令 timeout 不支持小数
	if [ $? != 0 ] && [ "$error" != "" ];then
		read -t 1 -s -n 1 key
	fi

	if [ $key ];then
		if [ $key == "a" ];then
			if [ $direction != "right" ];then
				direction="left"
			fi
		elif [ $key == "d" ];then
			if [ $direction != "left" ];then
				direction="right"
			fi
		elif [ $key == "w" ];then
			if [ $direction != "down" ];then
				direction="up"
			fi
		elif [ $key == "s" ];then
			if [ $direction != "up" ];then
				direction="down"
			fi
		fi
	fi
}

# 游戏结束画面
showGameOver() {
	local line_posi=$(( (boundary_d-boundary_u)/2+boundary_u-2 ))
	local col_posi=$(( (boundary_r-boundary_l)/2+boundary_l-18 ))
	echo -e "\033[$((line_posi + 0 ));${col_posi}H\033[1;31m-----------------------------------\033[0m"
	echo -e "\033[$((line_posi + 1 ));${col_posi}H\033[1;31m|                                 |\033[0m"
	echo -e "\033[$((line_posi + 2 ));${col_posi}H\033[1;31m|      Sorry , You Are Dead !     |\033[0m"
	echo -e "\033[$((line_posi + 3 ));${col_posi}H\033[1;31m|                                 |\033[0m"
 	echo -e "\033[$((line_posi + 4 ));${col_posi}H\033[1;31m-----------------------------------\033[0m"
	tput cnorm
	printf "\033[$((boundary_d+1));$((boundary_r+1))H\n\033[0m"
}

# 速度信息
printSpeed() {
	printf "\033[$((boundary_u+10));$((boundary_r+3))\
		H\033[42m\033[31mSpeed\033[0m  \033[1;34m$game_speed \033[0m"
}

# 得分信息
printScore() {
	printf "\033[$((boundary_u+8));$((boundary_r+3))\
		H\033[43m\033[31mScore\033[0m  \033[1;34m$game_score\033[0m"
	
	# 更新速度
	if (($game_score > 10 && $game_score <= 20));then
		game_speed=6
		printSpeed
	elif (($game_score > 20 && $game_score <= 30));then
		game_speed=10
		printSpeed
	elif (($game_score > 30 && $game_score <= 40));then
		game_speed=14
		printSpeed
	elif (($game_score > 40 && $game_score <= 50));then
		game_speed=18
		printSpeed
	elif (($game_score > 50 && $game_score <= 60));then
		game_speed=22
		printSpeed
	fi
}

snakeFrame() {
	# 隐藏光标
	tput civis
	# 初始化食物
	getFood
	# 保存之前的末尾坐标
	pre_last_position_x=$((snake_array[snake_len-2]-2))
	pre_last_position_y=${snake_array[snake_len-1]}
	# 是否获取食物
	isGetFood=false
	# 获取食物后新的坐标
	new_position_x=10
	new_position_y=10
	# 游戏是否结束
	isGameOver=false

	stop=false
	trap "stop=true" 10
	while ! $stop;do
		# 获取蛇头坐标
		head_position_x=${snake_array[0]}
		head_position_y=${snake_array[1]}
		# 判断是否获得食物
		if ((head_position_x==food_x&&head_position_y==food_y));then
			isGetFood=true
			# 加分
			((game_score++))
			printScore
			# 获取新的像素坐标
			new_position_x=${snake_array[snake_len-2]}
			new_position_y=${snake_array[snake_len-1]}
			# 获得新的食物
			getFood
		fi
		# 将蛇的像素全部绘制而出
		for ((i=snake_len-2;i>=0;i=i-2));do
			drawBlock $pre_last_position_y $pre_last_position_x
			if ((i==0));then
				drawBlock $head_position_y $head_position_x $head_color
				# 计算下一帧蛇头的像素坐标
				if [ $direction == "left" ];then
					if ((head_position_x<=boundary_inner_l));then
						head_position_x=$boundary_inner_r
					else
						head_position_x=$((head_position_x-2))
					fi	
				elif [ $direction == "right" ];then
					if ((head_position_x>=boundary_inner_r));then
						head_position_x=$boundary_inner_l
				 	else
						head_position_x=$((head_position_x+2))
					fi	
				elif  [ $direction == "up" ];then
					if ((head_position_y<=boundary_inner_u));then
						head_position_y=$boundary_inner_d
					else
						head_position_y=$((head_position_y-1))
					fi	
				elif [ $direction == "down" ];then
					if ((head_position_y>=boundary_inner_d));then
						head_position_y=$boundary_inner_u
					else
						head_position_y=$((head_position_y+1))
					fi	
				fi
				# 进行游戏判断
				for ((j=2;j<snake_len;j=j+2));do
					if ((snake_array[j]==head_position_x&&snake_array[j+1]==head_position_y));then
						isGameOver=true
						break
					fi
				done
			else
				if ((i>=snake_len-2));then
					pre_last_position_x=${snake_array[snake_len-2]}
					pre_last_position_y=${snake_array[snake_len-1]}
				fi
				drawBlock ${snake_array[i+1]} ${snake_array[i]} $body_color
				snake_array[i+1]=${snake_array[i-1]}
				snake_array[i]=${snake_array[i-2]}
			fi
		done
		while $isGameOver;do
			showGameOver
			sleep 100
		done
		while $isGetFood;do
			isGetFood=false
			snake_array[${#snake_array[@]}]=$new_position_x
			snake_array[${#snake_array[@]}]=$new_position_y
			snake_len=${#snake_array[@]}
			pre_last_position_x=${snake_array[snake_len-2]}
			pre_last_position_y=${snake_array[snake_len-1]}
			break
		done
		snake_array[0]=$head_position_x
		snake_array[1]=$head_position_y
		controlGame
	done
}

clear
drawBoundary
printSpeed
printScore
snakeFrame
