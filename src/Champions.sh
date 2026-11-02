#!/bin/bash

if [ $# -gt 1 ]; then
    echo "Error: Demasiados argumentos."
    exit 1
fi

if [ "$1" = "-g" ]; then
    echo "******************************"
    echo "           DEV TEAM           "
    echo "******************************"
    echo "    Daniel Sánchez Salvador   "
    echo "    Juan Peguero García       "
    echo " Sistemas Operativos I - PB3  "
    echo "******************************"
    exit 0
fi

# BORRAR COMENTARIO: hay que cambiar "../cfg/" por "./" antes de entregar el .ZIP, ya que el enunciado exige que estén en la misma carpeta que Champions.sh
CONFIG="../cfg/config.cfg"
EQUIPOS="../cfg/equipos.cfg"
DECISIONES="../cfg/decisiones.cfg"

if [ ! -f "$CONFIG" -o ! -f "$EQUIPOS" -o ! -f "$DECISIONES" ]; then
    echo "Faltan archivos clave de configuración"
    exit 1
fi

if [ ! -r "$CONFIG" -o ! -w "$CONFIG" -o ! -r "$EQUIPOS" -o ! -r "$DECISIONES" ]; then
    echo "Error en los permisos de los archivos de configuración"
    exit 1
fi


###FUNCIONES AUXILIARES DE CONFIGURACION

function get_config_val(){
    key="$1"
    grep "^${key}=" < "$CONFIG" | cut -f 2 -d "=" #esto busca la linea que empiece por "nombre" y luego extrae el valor detras del =
}

function cargar_config(){
    NOMBRE=$(get_config_val "NOMBRE")
    EQUIPO=$(get_config_val "EQUIPO")
    VICTORIAS=$(get_config_val "VICTORIAS")
    LOG=$(get_config_val "LOG")
    CLASIFICACION=$(get_config_val "CLASIFICACION")
}

function guardar_config(){
    echo "NOMBRE=$NOMBRE" > "$CONFIG"
    echo "EQUIPO=$EQUIPO" >> "$CONFIG"
    echo "VICTORIAS=$VICTORIAS" >> "$CONFIG"
    echo "LOG=$LOG" >> "$CONFIG"
    echo "CLASIFICACION=$CLASIFICACION" >> "$CONFIG"
}

function cargar_datos(){
    for id in $(seq 1 16); do
        linea=$(grep "^${id}|" < "$EQUIPOS")
        EQ_NOM[$id]=$(echo "$linea" | cut -f 2 -d "|")
        EQ_NIV[$id]=$(echo "$linea" | cut -f 3 -d "|")
    done

    for i in 1 2 3 4; do
        linea_d=$(head -$i < "$DECISIONES" | tail -1)
        DEC_NOM[$((i - 1))]=$(echo "$linea_d" | cut -f 1 -d "|")
    done
}

function randomizar_equipos(){
    array=("$@")
    i=$(( ${#array[@]} - 1 ))
    local i tmp
    while [ "$i" -gt 0 ]; do
        j=$((RANDOM % (i + 1)))
        tmp="${array[$i]}"
        array[$i]="${array[$j]}"
        array[$j]="$tmp"
        i=$((i - 1))
    done
    echo "${array[@]}"
}

function jugar_champions(){
                
    #Validaciones, limpieza de archivos y sorteo
    if [ -z "$NOMBRE" ]; then
        echo "Error: el nombre del jugador está vacío, abra el menú de configuración para cambiarlo."
        return 1
    fi

    echo ""  
    echo "**************************************************"
    echo "                INICIANDO CHAMPIONS               "
    echo "**************************************************"

    > "$LOG"
    > "$CLASIFICACION"

    for id in $(seq 1 16); do
        GF[$id]=0
        GC[$id]=0
        RONDA[$id]="Octavos"
    done 

    equipos_jugando=($(randomizar_equipos $(seq 1 16)))
    jugador_eliminado=0
    echo "Sorteo de octavos realizado con éxito"

    echo ""
    echo "*****************************"
    echo "      OCTAVOS DE FINAL       "
    echo "*****************************"

    sig_ronda=()

    lim=$(( ${#equipos_jugando[@]} - 2 ))
    for i in $(seq 0 2 "$lim"); do
        eq1="${equipos_jugando[$i]}"
        i_eq2=$((i + 1))
        eq2="${equipos_jugando[$i_eq2]}"

        #ida, donde el eq1 es el local
        res_ida=$(simular_partido "$eq1" "$eq2" 1 0)
        goles1_ida=$(echo "$res_ida" | cut -f 1 -d "|")
        goles2_ida=$(echo "$res_ida" | cut -f 2 -d "|")
        dec1_ida=$(echo "$res_ida" | cut -f 3 -d "|")
        dec2_ida=$(echo "$res_ida" | cut -f 4 -d "|")

        GF[$eq1]=$((GF[$eq1] + goles1_ida)); GC[$eq1]=$((GC[$eq1] + goles2_ida))
        GF[$eq2]=$((GF[$eq2] + goles2_ida)); GC[$eq2]=$((GC[$eq2] + goles1_ida))

    
        echo "Octavos | Ida | ${EQ_NOM[$eq1]} | ${EQ_NOM[$eq2]} | $goles1_ida | $goles2_ida | $dec1_ida | $dec2_ida |" >> "$LOG"

        #vuelta, lo mismo pero al reves, ahora local es eq2
        res_ida=$(simular_partido "$eq2" "$eq1" 1 0)
        goles2_vuelta=$(echo "$res_ida" | cut -f 1 -d "|")
        goles1_vuelta=$(echo "$res_ida" | cut -f 2 -d "|")
        dec2_vuelta=$(echo "$res_ida" | cut -f 3 -d "|")
        dec1_vuelta=$(echo "$res_ida" | cut -f 4 -d "|")

        GF[$eq2]=$((GF[$eq2] + goles2_vuelta)); GC[$eq2]=$((GC[$eq2] + goles1_vuelta))
        GF[$eq1]=$((GF[$eq1] + goles1_vuelta)); GC[$eq1]=$((GC[$eq1] + goles2_vuelta))

        #ahora hay que sumar, decidir el ganador y mostrar por pantalla el resultado

        total1=$((goles1_ida + goles1_vuelta))
        total2=$((goles2_ida + goles2_vuelta))

        penaltis=""
        ganador_elim=""
        if [ "$total1" -gt "$total2" ]; then
            ganador_elim="$eq1"
        elif [ "$total2" -gt "$total1" ]; then
            ganador_elim="$eq2"
        else
            #ha habiado empate, recurrimos a los penaltis
            res_pen=$(simular_penaltis "$eq1" "$eq2")
            penaltis=$(echo "$res_pen" | cut -f 1 -d "|")
            ganador_elim=$(echo "$res_pen" | cut -f 2 -d "|")
        fi

        echo "Octavos | vuelta | ${EQ_NOM[$eq2]} | ${EQ_NOM[$eq1]} | $goles2_vuelta | $goles1_vuelta | $dec2_vuelta | $dec1_vuelta | $penaltis" >> "$LOG"

        sig_ronda+=("$ganador_elim")
        perdedor=$([ "$ganador_elim" -eq "$eq1" ] && echo "$eq2" || echo "$eq1")
        RONDA[$perdedor]="Octavos"

        if [ "$eq1" -eq "$EQUIPO" ] || [ "$eq2" -eq "$EQUIPO" ]; then
            echo "*********************************************************"
            echo "Octavos de final"
            echo "IDA: ${EQ_NOM[$eq1]} $goles1_ida - $goles2_ida ${EQ_NOM[$eq2]}"
            echo "VUELTA: ${EQ_NOM[$eq2]} $goles2_vuelta - $goles1_vuelta ${EQ_NOM[$eq1]}"
            echo "GLOBAL: ${EQ_NOM[$eq1]} $total1 - $total2 ${EQ_NOM[$eq2]}"
            [ "$penaltis" != "-" ] && echo "Penaltis: $penaltis"
            echo "Clasificado: ${EQ_NOM[$ganador_elim]}"
            echo "*********************************************************"
            echo "Pulsa ENTER para continuar: "
            read
        fi
    done
}

function simular_partido(){
    eqA="$1"
    eqB="$2"
    es_localA="$3"
    es_final="$4"
    

    nivA="${EQ_NIV[$eqA]}"
    nivB="${EQ_NIV[$eqB]}"

    idx_A=$((RANDOM % 4))
    idx_B=$((RANDOM % 4))
    decA="${DEC_NOM[$idx_A]}"
    decB="${DEC_NOM[$idx_B]}"

    #de acuerdo con el enunciado, este es el desarrollo de un partido:


    #1-Cada equpo dispondrá de 5 oportunidades para marcar un gol
    oportA=5
    oportB=5

    if [ "$decB" = "Expulsión" ]; then oportA=$((oportA - 1)); fi
    if [ "$decA" = "Expulsión" ]; then oportB=$((oportB - 1)); fi
    [ "$decA" = "Tiempo añadido" ] && oportA=$((oportA + 1));
    [ "$decB" = "Tiempo añadido" ] && oportB=$((oportB + 1))

    # 2 el numero tope que tiene cada equipo para meter gol
    limA=$((15 + 10 * nivA))
    limB=$((15 + 10 * nivB))

    if [ "$es_final" -eq 0 ]; then
        if [ "$es_localA" -eq 1 ]; then
            limA=$((limA + 5))
        else
            limB=$((limB + 5))
        fi
    fi

    # 3 oportundiades de gol: generacion de un numero aleatorio

    golesA=0
    for i in $(seq 0 "$oportA"); do
        probA=$(( (RANDOM % 100) + 1))
        if [ "$probA" -le "$limA" ]; then
            golesA=$((golesA + 1))
        fi
    done


    golesB=0
    for j in $(seq 0 "$oportB"); do
        probB=$(( (RANDOM % 100) + 1))
        if [ "$probB" -le "$limB" ]; then
            golesB=$((golesB + 1))
        fi
    done

    # 4despues de tirar, vemos si han decidido pitar penalti o var

    if [ "$decA" = "Penalti" ]; then golesA=$((golesA + 1)); fi
    if [ "$decB" = "Penalti" ]; then golesB=$((golesB + 1)); fi

    if [ "$decA" = "VAR" ] && [ "$decB" = "VAR" ]; then
        :
    else
        if [ "$decA" = "VAR" ] && [ "$golesB" -gt 0 ]; then golesB=$((golesB - 1)); fi
        if [ "$decB" = "VAR" ] && [ "$golesA" -gt 0 ]; then golesA=$((golesA - 1)); fi
    fi

    echo "$golesA|$golesB|$decA|$decB"
}

function simular_penaltis(){
    eqA="$1"
    eqB="$2"
    penA=0
    penB=0

    for numero in {1..5}; do
        rA=$(( (RANDOM % 100) + 1 ))
        if [ "$rA" -le 75 ]; then penA=$((penA + 1)); 
        fi

        rB=$(( (RANDOM % 100) + 1))
        if [ "$rB" -le 75 ]; then penB=$((penB + 1));
        fi
    done

    while [ "$penA" -eq "$penB" ]; do
        rA=$(( (RANDOM % 100) + 1 ))
        rB=$(( (RANDOM % 100) + 1 ))
        if [ "$rA" -le 75 ]; then penA=$((penA + 1)); fi
        if [ "$rB" -le 75 ]; then penB=$((penB + 1)); fi
    done

    ganador=""
    if [ "$penA" -gt "$penB" ]; then
        ganador="$eqA"
    else
        ganador="$eqB"
    fi

    echo "$penA-$penB|$ganador"
}

###MOSTRAR_MENU_CONFIG
menu_config(){
    salir_c=0
    while [ $salir_c -eq 0 ]; do
        echo ""
        echo "*****************MENÚ DE CONFIGURACIÓN*****************"
        echo "1) Nombre del jugador: $NOMBRE"
        echo "2) Equipo seleccionado (ID): $EQUIPO (${EQ_NOM[$EQUIPO]})"
        echo "3) Archivo de LOG: $LOG"
        echo "4) Archivo de CLASIFICACION: $CLASIFICACION"
        echo "5) Salir de configuración"
        echo "*******************************************************"
        echo ""

        echo "Seleccione una opción (1-5): "
        read
        opt_c="$REPLY"

        case "$opt_c" in
            1) 
                echo "Introduzca el nuevo nombre: "
                read
                new_nom="$REPLY"
                if [ -n "$new_nom" ]; then
                    NOMBRE="$new_nom"
                    guardar_config
                    echo "Nombre actualizado a: $NOMBRE"
                else
                    echo "El nombre no puede estar vacío"
                fi
                ;;
            2)  
                echo "Listado de equipos:"
                cat "$EQUIPOS"
                echo ""
                echo "Introduzca el ID del equipo: "
                read
                new_id="$REPLY"
                if [ -n "$new_id" ]; then
                    grep "^${new_id}|" < "$EQUIPOS" > /dev/null 2>&1
                    if [ $? -eq 0 ]; then
                        EQUIPO="$new_id"
                        guardar_config
                        echo "El ID del Equipo ha sido actualizado a: $new_id (${EQ_NOM[$EQUIPO]})"
                    else
                        echo "Error: El ID introducido no existe en equipos.cfg"
                    fi
                else
                    echo "Error al actualizar el equipo"
                fi
                ;;
            3)
                echo "Introduzca la nueva ruta donde almacenar los partidos: "
                read
                new_log="$REPLY"
                if [ -n "$new_log" ]; then
                    LOG="$new_log"
                    guardar_config
                    echo "La ruta ha cambiado a: $new_log"
                else
                    echo "La ruta está vacía"
                fi
                ;;
            4)  
                echo "Introduzca la nueva ruta donde almacenarán las clasificaciones: "
                read
                new_clas="$REPLY"
                if [ -n "$new_clas" ]; then
                    CLASIFICACION="$new_clas"
                    guardar_config
                    echo "La ruta ha cambiado a: $new_clas"
                else
                    echo "La ruta está vacía o no es válida"
                fi
                ;;
            5)  
                echo "SALIENDO..."
                salir_c=1
                ;;
            *)
                echo "Opción no válida"
                ;;
        esac    
    done
}

function menu_reinicio(){
    echo ""
    echo "¿Está seguro de que desea reiniciar configuración, log y clasificación? (S/N): "
    read
    confirmacion="$REPLY"

    case "$confirmacion" in
        S|s)
            if [ -f "$LOG" ]; then
                cat /dev/null > "$LOG"
            fi
            if [ -f "$CLASIFICACION" ]; then
                cat /dev/null > "$CLASIFICACION"
            fi

            NOMBRE=""
            EQUIPO=1
            VICTORIAS=0
            LOG="./log.cfg"
            CLASIFICACION="./clasificacion.cfg"
            guardar_config

            cat /dev/null > "$LOG"
            cat /dev/null > "$CLASIFICACION"

            echo "Reinicio completado correctamente."
            ;;
        *)
            echo "Reinicio cancelado."
            ;;
    esac
}

cargar_config
cargar_datos

while true; do
    echo ""
    echo "C) CONFIGURACION"
    echo "J) JUGAR CHAMPIONS"
    echo "E) ESTADÍSTICAS"
    echo "R) REINICIO"
    echo "S) SALIR"
    echo '"Champions League". Introduzca una opción >> '
    read
    opcion_menu="$REPLY"

    case "$opcion_menu" in
        C|c)
            menu_config
            ;;
        J|j)
            jugar_champions
            #echo "jugar champions"
            ;;
        E|e)
            # BORRAR COMENTARIO: Aquí se llama a la función mostrar_estadisticas cuando la tengamos
            echo "Opción Estadísticas"
            ;;
        R|r)
            menu_reinicio
            ;;
        S|s)
            echo "Fin del programa."
            exit 0
            ;;
        *)
            echo "Opción no válida."
            ;;
    esac

    echo ""
    echo "Pulse INTRO para continuar"
    read
done




