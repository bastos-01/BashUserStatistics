#!/bin/bash
sort="sort ";
verificacao=0
argumentos=("$@")

usage () {
	echo "
	Utilização do script:
	
	./comparestats.sh <options> <filename1> <filename2> : compara os dois ficheiros mostrando a diferença dos valores

	Options:

	Ordering:
		-r : ordena por ordem decrescente
		-n : ordena pelo número de sessões
		-t : ordena pelo tempo total 
		-a : ordena pelo temo máximo
		-i : ordena pelo tempo mínimo 

	"
}
while getopts "nrtai" o; do
    case "${o}" in
		n)
			if [ $verificacao == 0 ]; then
				sort+="-n -k2 ";
				verificacao=1
			else #se verificação for diferente de 0, já foi ordenada e por isso não pode ter mais opções de ordenação 
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;
		r)
				sort+="-r";	
			;;
		t)
			if [ $verificacao == 0 ]; then
				sort+="-n -k3 ";
				verificacao=1
			else #se verificação for diferente de 0, já foi ordenada e por isso não pode ter mais opções de ordenação 
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;	
		a)
			if [ $verificacao == 0 ]; then
				sort+="-n -k4 ";
				verificacao=1
			else #se verificação for diferente de 0, já foi ordenada e por isso não pode ter mais opções de ordenação 
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;
		i)
			if [ $verificacao == 0 ]; then
				sort+="-n -k5 ";
				verificacao=1
			else #se verificação for diferente de 0, já foi ordenada e por isso não pode ter mais opções de ordenação 
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;
        *)
			usage
			exit 1;
            ;;
    esac
done
shift $((OPTIND-1))	

#---------------------------


if [[ ! -e $1 ]];then
	echo "Primeiro ficheiro não encontrado!"
	exit 1;
else
	userstats1=$1
fi

if [[ ! -e $2 ]];then
	echo "Segundo ficheiro não encontrado!"
	exit 1;
else
	userstats2=$2
fi

#---------------------------

while IFS= read -r linha
do
	IFS=$'\n'
  statsFirstUser+=($linha);
done < $userstats1

while IFS= read -r linha
do
	IFS=$'\n'
  statsSecondUser+=($linha);
done < $userstats2

#---------------------------

for user1 in ${statsFirstUser[@]}
do
	nome1=$(echo "$user1" | awk '{print $1}');
	for user2 in ${statsSecondUser[@]}
	do
		nome2=$(echo "$user2" | awk '{print $1}');
		if [ $nome1 == $nome2 ]; then
			sessoes=$(($(echo "$user1" | awk '{print $2}') - $(echo "$user2" | awk '{print $2}')))
			tempoTotal=$(($(echo "$user1" | awk '{print $3}') - $(echo "$user2" | awk '{print $3}')))
			minTemp=$(($(echo "$user1" | awk '{print $4}') - $(echo "$user2" | awk '{print $4}')))
			maxTemp=$(($(echo "$user1" | awk '{print $5}') - $(echo "$user2" | awk '{print $5}')))
			finalStats+=("$nome1 $sessoes $tempoTotal $minTemp $maxTemp")
		fi
	done
done

for user1 in ${statsFirstUser[@]}
do
	flag=0
	nome1=$(echo "$user1" | awk '{print $1}');
	for finalUser in ${finalStats[@]}
	do
		nomeFinal=$(echo "$finalUser" | awk '{print $1}');
		if [ $nome1 == $nomeFinal ] ;then
			flag=1;
		fi
	done

	if [[ $flag -eq 0 ]]; then
		finalStats+=("$user1")
	fi
done

for user2 in ${statsSecondUser[@]}
do
	flag=0
	nome2=$(echo "$user2" | awk '{print $1}');
	for finalUser in ${finalStats[@]}
	do
		nomeFinal=$(echo "$finalUser" | awk '{print $1}');
		if [ $nome2 == $nomeFinal ] ;then
			flag=1;
		fi
	done

	if [[ $flag -eq 0 ]]; then
		finalStats+=("$user2")
	fi
done

IFS=$' ' #para conseguir dar print
printf '%s \n' "${finalStats[@]}" | ${sort}






















