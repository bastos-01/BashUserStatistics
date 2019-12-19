#!/bin/bash
sort="sort ";
verificacao=0
options="last"
argumentos=("$@")

usage() { echo "
	Utilização do script:

	./userstats.sh <options> : calcula os valores de tempo totais, máximos e mínimos das sessões dos utilizadores selecionados

	Options:

	-f <filename> : excuta o script para outro ficheiro 

	User fiters:
		-u <name> : filtra os nomes apenas executando o script para o nome especificado

	Date filters:
		-s <Month Day Hour> : excuta o script para datas posteriores à especificada
		-e <Month Day Hour> : excuta o script para datas anteriores à especificada

	Ordering:
		-r : Ordena por ordem decrescente
		-n : Ordena por número de sessões
		-t : Ordena por tempo total das sessões
		-a : Ordena por tempo máximo de sessão 
		-i : Ordena por tempo mínimo de sessão
				
	Nota: Não pode utilizar duas ordenações ao mesmo tempo, a não ser que uma delas seja '-r'

			"
		}

while getopts "g:u:s:e:f::nrtai" o; do
    case "${o}" in
        u)	
			u="${OPTARG}"
            ;;
        f)
            f=${OPTARG}
            if [ ! -e $f ]; then #se o ficheiro não existe
            	echo "O ficheiro não existe, por favor coloque um ficheiro válido!"
            	exit 1;
            else
            	options="${options} -f $f"
            fi
            ;;
		s)
			if ! date -d "$OPTARG" "+%Y-%m-%d" >/dev/null 2>&1; then #se nao for colocada a data no formato certo 
				echo "Please type the date in the format 'month day hour' "
				exit 1;
			fi
			month=$(date -d "$OPTARG" +"%m") #converte a string colocada do mes no respetivo número
			day=${OPTARG:4:2}
			hour=${OPTARG:6}
			if [[ $hour == *":"* ]];then # verifica se a data tem hora (vendo se tem o caracter ':')
				temp=$(date -d "$OPTARG" +"%Y-%m-%d%H:%M")
				options="${options} -s $temp"
			else # não tendo hora, executa com o formato normal sem hora
				options="${options} -s 2019-$month-$day" 
			fi
			;;
		e)
			if ! date -d "$OPTARG" "+%Y-%m-%d" >/dev/null 2>&1; then #se nao for colocada a data no formato certo
				echo "Please type the date in the format 'month day hour' "
				exit 1;
			fi
			month=$(date -d "$OPTARG" +"%m") #converte a string colocada do mes no respetivo número
			day=${OPTARG:4:2}
			hour=${OPTARG:6}
			if [[ $hour == *":"* ]];then # verifica se a data tem hora (vendo se tem o caracter ':'
				temp=$(date -d "$OPTARG" +"%Y-%m-%d%H:%M")
				options="${options} -t $temp"
			else # não tendo hora, executa com o formato normal sem hora
				options="${options} -t 2019-$month-$day" 
			fi
			;;
		n)
			if [ $verificacao == 0 ]; then
				sort+="-n -k2 ";
				verificacao=1
			else #tendo a verificação diferente de 0, já foi usado uma opção de ordenação e por isso dá erro e termina
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
			else #tendo a verificação diferente de 0, já foi usado uma opção de ordenação e por isso dá erro e termina
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;	
		a)
			if [ $verificacao == 0 ]; then
				sort+="-n -k4 ";
				verificacao=1
			else #tendo a verificação diferente de 0, já foi usado uma opção de ordenação e por isso dá erro e termina
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;
		i)
			if [ $verificacao == 0 ]; then
				sort+="-n -k5 ";
				verificacao=1
			else #tendo a verificação diferente de 0, já foi usado uma opção de ordenação e por isso dá erro e termina
				echo "Não pode usar duas opções de ordenação!"
				exit 1;
			fi
			;;
        ?) #colocando uma opção inválida ou não colocando um argumento onde era obrigatório, dá print da mensagem 'usage' e termina
			usage
			exit 1;
            ;;
    esac
done
shift $((OPTIND-1))	


coluna='$1'
pickColuna="| awk '{print $coluna}'"
if [[ ! -z $u ]];then #se foi usado -u, filtra-se já os utilizadores passados
	finalOptions="${options} $pickColuna | grep $u | grep -v "reboot" | grep -v "shutdown" | grep -v "wtmp" | sort | uniq"
else
	finalOptions="${options} $pickColuna | grep -v "reboot" | grep -v "shutdown" | grep -v "wtmp" | sort | uniq"
fi

finalUsers=($(eval $finalOptions))

getUsersStats()	{ #função que retorna 

if  [[ ${finalUsers[@]} ]] ;then #se existirem utilizadores com as opções selecionadas
	for i in ${finalUsers[@]} #percorre os utilizadores 
	do
		if [[ ${argumentos[@]} ]]; then
			for x in ${argumentos[@]} #percorre as opções selecionadas
			do
				if [ $x == "-s" ] || [ $x == "-e" ] || [ $x == "-f" ]  #quando são usadas as opções -s, -e e -f
				then
					counter=($($options | awk '{print $1}' | grep $i | wc -l ))
					timeInicio=($($options | grep "$i" | awk '{print $10}' | grep -v "in" | grep -v "logged" | grep -v "no"))
					break
				else #quando são usadas apenas opções de ordenação
					counter=($( last | awk '{print $1;}' | grep "$i" | wc -l ))
					timeInicio=($( last | grep "$i" | awk '{print $10;}' | grep -v "in" | grep -v "logged" | grep -v "no"))
				fi
			done
		else #se não são usadas opções nenhumas 
			counter=($($options | awk '{print $1}' | grep -i "$i" | wc -l ))
			timeInicio=($( $options | grep "$i" | awk '{print $10;}' | grep -v "in" | grep -v "logged" | grep -v "no"))	
		fi
			
		tempoTotal=0;
		#inicializa as variáveis
		min_time=10000000
		max_time=0
		for k in ${timeInicio[@]} #percorre os tempos de sessão do utilizador
		do
			if [[ ${#k} == 10 ]];then #quando o tempo de sessão está entre 10 e 100 dias
				k0=${k:1:2}
				k1=${k:4:2}
				k2=${k:7:8}
				k2=${k2//)}
				temp_time=$(( 10#$k0*24*60 + 10#$k1*60 + 10#$k2))
			elif [[ ${#k} == 9 ]];then	#quando o tempo de sessão está entre 1 e 10 dias
				k0=${k:1:1}
				k1=${k:3:2}
				k2=${k:6:7}
				k2=${k2//)}
				temp_time=$(( 10#$k0*24*60 + 10#$k1*60 + 10#$k2))
			else #quando o tempo de sessão é inferior a 1 dia
				k1=${k:1:2}
				k2=${k:4:5}
				k2=${k2//)}
				temp_time=$(( 10#$k1*60 + 10#$k2 ))
			fi	
			if [[ $temp_time -lt $min_time ]];then #se o tempo calculado for inferior ao tempo mínimo atual, substitui o tempo minimo
				min_time=$temp_time;
			fi
			if [[ $temp_time -gt $max_time ]];then #se o tempo calculado for superior ao tempo maximo atual, substitui o tempo maximo
				max_time=$temp_time;
			fi
			tempoTotal=$(( $tempoTotal+$temp_time )) #adiciona o tempo ao tempo total do utilizador
		done

		userstats+=("$i $counter $tempoTotal $max_time $min_time") #adiciona as stats do utilizador corrente ao array final
		
	done
else #se não foram encontrados utilizadores
	echo "Não foram encontrados utilizadores para as opções selecionadas!"
fi
}


getUsersStats #calcula as stats dosutilizadores
printf "%s\n" "${userstats[@]}" | ${sort} #print das stats dos utilizadores com a ordenação (variavel sort) selecionada
