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

CONFIG="./config.cfg"
EQUIPOS="./equipos.cfg"
DECISIONES="./decisiones.cfg"

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
    grep "^${key}=" < "$CONFIG" | cut -f 2 -d "="
}

function cargar_config(){
    NOMBRE=$(get_config_val "NOMBRE")
    EQUIPO=$(get_config_val "EQUIPO")
    VICTORIAS=$(get_config_val "VICTORIAS")
    LOG=$(get_config_val "LOG")
    CLASIFICACION=$(get_config_val "CLASIFICACION")

    NO_ES_NUMERO=$(echo "$EQUIPO" | grep -v "^[0-9]*$")
    if [ -n "$NO_ES_NUMERO" ] || [ -z "$EQUIPO" ]; then
        EQUIPO=1
    fi

    grep "^${EQUIPO}|" < "$EQUIPOS" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        EQUIPO=1
    fi
}

function guardar_config(){
    echo "NOMBRE=$NOMBRE" > "$CONFIG"
    echo "EQUIPO=$EQUIPO" >> "$CONFIG"
    echo "VICTORIAS=$VICTORIAS" >> "$CONFIG"
    echo "LOG=$LOG" >> "$CONFIG"
    echo "CLASIFICACION=$CLASIFICACION" >> "$CONFIG"
}

function cargar_datos(){
    local id=1
    while [ "$id" -le 16 ]; do
        linea=$(grep "^${id}|" < "$EQUIPOS")
        EQ_NOM[$id]=$(echo "$linea" | cut -f 2 -d "|")
        EQ_NIV[$id]=$(echo "$linea" | cut -f 3 -d "|")
        id=$((id + 1))
    done

    local i
    for i in 1 2 3 4; do
        linea_d=$(head -$i < "$DECISIONES" | tail -1)
        DEC_NOM[$((i - 1))]=$(echo "$linea_d" | cut -f 1 -d "|")
    done
}

function randomizar_equipos(){
    local i j temp
    local arr=("$@")

    i=$((${#arr[@]} - 1))
    while [ "$i" -gt 0 ]; do
        j=$((RANDOM % (i+1)))
        temp="${arr[$i]}"
        arr[$i]="${arr[$j]}"
        arr[$j]="$temp"
        i=$((i - 1))
    done
    echo "${arr[@]}"
}

function limpiar_espacios(){
    local cad="$1"
    cad="${cad# }"
    cad="${cad% }"
    echo "$cad"
}

function simular_partido(){
    local eqA="$1"
    local eqB="$2"
    local es_localA="$3"
    local es_final="$4"
    
    local nivA="${EQ_NIV[$eqA]}"
    local nivB="${EQ_NIV[$eqB]}"

    local idx_A=$((RANDOM % 4))
    local idx_B=$((RANDOM % 4))
    local decA="${DEC_NOM[$idx_A]}"
    local decB="${DEC_NOM[$idx_B]}"

    local oportA=5
    local oportB=5

    if [ "$decB" = "Expulsión" ]; then oportA=$((oportA - 1)); fi
    if [ "$decA" = "Expulsión" ]; then oportB=$((oportB - 1)); fi
    if [ "$decA" = "Tiempo añadido" ]; then oportA=$((oportA + 1)); fi
    if [ "$decB" = "Tiempo añadido" ]; then oportB=$((oportB + 1)); fi

    local limA=$((15 + 10 * nivA))
    local limB=$((15 + 10 * nivB))

    if [ "$es_final" -eq 0 ]; then
        if [ "$es_localA" -eq 1 ]; then
            limA=$((limA + 5))
        else
            limB=$((limB + 5))
        fi
    fi

    local golesOP_A=0
    local probA
    local i=1
    while [ "$i" -le "$oportA" ]; do
        probA=$(( (RANDOM % 100) + 1))
        if [ "$probA" -le "$limA" ]; then
            golesOP_A=$((golesOP_A + 1))
        fi
        i=$((i + 1))
    done

    local golesOP_B=0
    local probB
    local j=1
    while [ "$j" -le "$oportB" ]; do
        probB=$(( (RANDOM % 100) + 1))
        if [ "$probB" -le "$limB" ]; then
            golesOP_B=$((golesOP_B + 1))
        fi
        j=$((j + 1))
    done

    local golesA=$golesOP_A
    local golesB=$golesOP_B
    local penA=0
    local penB=0

    if [ "$decA" = "Penalti" ]; then golesA=$((golesA + 1)); penA=1; fi
    if [ "$decB" = "Penalti" ]; then golesB=$((golesB + 1)); penB=1; fi

    local varA=0
    local varB=0
    if [ "$decA" = "VAR" -a "$decB" = "VAR" ]; then
        :
    else
        if [ "$decA" = "VAR" -a "$golesB" -gt 0 ]; then golesB=$((golesB - 1)); varA=1; fi
        if [ "$decB" = "VAR" -a "$golesA" -gt 0 ]; then golesA=$((golesA - 1)); varB=1; fi
    fi

    echo "$golesA|$golesB|$decA|$decB|$golesOP_A|$golesOP_B|$penA|$penB|$varA|$varB"
}

function simular_penaltis(){
    local eqA="$1"
    local eqB="$2"
    local penA=0
    local penB=0

    local rA
    local rB
    local numero
    for numero in 1 2 3 4 5; do
        rA=$(( (RANDOM % 100) + 1 ))
        if [ "$rA" -le 75 ]; then penA=$((penA + 1)); fi
        rB=$(( (RANDOM % 100) + 1))
        if [ "$rB" -le 75 ]; then penB=$((penB + 1)); fi
    done

    while [ "$penA" -eq "$penB" ]; do
        rA=$(( (RANDOM % 100) + 1 ))
        rB=$(( (RANDOM % 100) + 1 ))
        if [ "$rA" -le 75 ]; then penA=$((penA + 1)); fi
        if [ "$rB" -le 75 ]; then penB=$((penB + 1)); fi
    done

    local ganador=""
    if [ "$penA" -gt "$penB" ]; then
        ganador="$eqA"
    else
        ganador="$eqB"
    fi

    echo "$penA-$penB|$ganador"
}

function pintar_desglose_partido() {
    local tipo_p="$1"
    local eq1="$2"
    local eq2="$3"
    local gA="$4"
    local gB="$5"
    local d1="$6"
    local d2="$7"
    local opA="$8"
    local opB="$9"
    local p1="${10}"
    local p2="${11}"
    local v1="${12}"
    local v2="${13}"

    echo "$tipo_p: ${EQ_NOM[$eq1]} $gA - $gB ${EQ_NOM[$eq2]}"
    echo "Decisiones: $d1 | $d2"
    echo "Goles tras las oportunidades: $opA - $opB"
    
    if [ "$p1" -eq 1 ]; then echo "Penalti: +1 ${EQ_NOM[$eq1]}"; fi
    if [ "$p2" -eq 1 ]; then echo "Penalti: +1 ${EQ_NOM[$eq2]}"; fi
    
    if [ "$d1" = "VAR" -a "$d2" = "VAR" ]; then
        echo "VAR: Sin efecto"
    else
        if [ "$v1" -eq 1 ]; then echo "VAR: -1 ${EQ_NOM[$eq2]}"; fi
        if [ "$v2" -eq 1 ]; then echo "VAR: -1 ${EQ_NOM[$eq1]}"; fi
    fi
}

function jugar_champions(){
    if [ -z "$NOMBRE" ]; then
        echo "Error: el nombre del jugador está vacío, abra el menú de configuración para cambiarlo."
        return 1
    fi

    echo ""  
    echo "**************************************************"
    echo "                INICIANDO CHAMPIONS               "
    echo "**************************************************"

    cat /dev/null > "$LOG"
    cat /dev/null > "$CLASIFICACION"

    local id=1
    while [ "$id" -le 16 ]; do
        GF[$id]=0
        GC[$id]=0
        RONDA[$id]="Octavos"
        PESO_RONDA[$id]=1
        id=$((id + 1))
    done 

    equipos_jugando=($(randomizar_equipos 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16))
    jugador_eliminado=0
    campeon_torneo=""

    NOMBRES_RONDAS=("Octavos" "Cuartos" "Semifinales" "Final")
    TITULOS_RONDAS=("Octavos de final" "Cuartos de final" "Semifinales" "Final")

    local r_idx
    for r_idx in 0 1 2 3; do
        equipos_jugando=($(randomizar_equipos "${equipos_jugando[@]}"))
        R_NOM="${NOMBRES_RONDAS[$r_idx]}"
        R_TIT="${TITULOS_RONDAS[$r_idx]}"
        
        echo ""
        echo "*****************************"
        echo "      $R_TIT       "
        echo "*****************************"

        sig_ronda=()
        lim=$(( ${#equipos_jugando[@]} - 2 ))
        
        local i=0
        while [ "$i" -le "$lim" ]; do
            eq1="${equipos_jugando[$i]}"
            i_eq2=$((i + 1))
            eq2="${equipos_jugando[$i_eq2]}"
            
            if [ "$R_NOM" != "Final" ]; then
                res_ida=$(simular_partido "$eq1" "$eq2" 1 0)
                g1_i=$(echo "$res_ida" | cut -f 1 -d "|"); g2_i=$(echo "$res_ida" | cut -f 2 -d "|")
                d1_i=$(echo "$res_ida" | cut -f 3 -d "|"); d2_i=$(echo "$res_ida" | cut -f 4 -d "|")
                op1_i=$(echo "$res_ida" | cut -f 5 -d "|"); op2_i=$(echo "$res_ida" | cut -f 6 -d "|")
                p1_i=$(echo "$res_ida" | cut -f 7 -d "|"); p2_i=$(echo "$res_ida" | cut -f 8 -d "|")
                v1_i=$(echo "$res_ida" | cut -f 9 -d "|"); v2_i=$(echo "$res_ida" | cut -f 10 -d "|")

                GF[$eq1]=$((GF[$eq1] + g1_i)); GC[$eq1]=$((GC[$eq1] + g2_i))
                GF[$eq2]=$((GF[$eq2] + g2_i)); GC[$eq2]=$((GC[$eq2] + g1_i))
            
                echo "$R_NOM | Ida | ${EQ_NOM[$eq1]} | ${EQ_NOM[$eq2]} | $g1_i | $g2_i | $d1_i | $d2_i | -" >> "$LOG"

                res_vue=$(simular_partido "$eq2" "$eq1" 1 0)
                g2_v=$(echo "$res_vue" | cut -f 1 -d "|"); g1_v=$(echo "$res_vue" | cut -f 2 -d "|")
                d2_v=$(echo "$res_vue" | cut -f 3 -d "|"); d1_v=$(echo "$res_vue" | cut -f 4 -d "|")
                op2_v=$(echo "$res_vue" | cut -f 5 -d "|"); op1_v=$(echo "$res_vue" | cut -f 6 -d "|")
                p2_v=$(echo "$res_vue" | cut -f 7 -d "|"); p1_v=$(echo "$res_vue" | cut -f 8 -d "|")
                v2_v=$(echo "$res_vue" | cut -f 9 -d "|"); v1_v=$(echo "$res_vue" | cut -f 10 -d "|")

                GF[$eq2]=$((GF[$eq2] + g2_v)); GC[$eq2]=$((GC[$eq2] + g1_v))
                GF[$eq1]=$((GF[$eq1] + g1_v)); GC[$eq1]=$((GC[$eq1] + g2_v))

                total1=$((g1_i + g1_v))
                total2=$((g2_i + g2_v))

                penaltis="-"
                ganador_elim=""
                if [ "$total1" -gt "$total2" ]; then
                    ganador_elim="$eq1"
                elif [ "$total2" -gt "$total1" ]; then
                    ganador_elim="$eq2"
                else
                    res_pen=$(simular_penaltis "$eq1" "$eq2")
                    penaltis=$(echo "$res_pen" | cut -f 1 -d "|")
                    ganador_elim=$(echo "$res_pen" | cut -f 2 -d "|")
                fi

                echo "$R_NOM | Vuelta | ${EQ_NOM[$eq2]} | ${EQ_NOM[$eq1]} | $g2_v | $g1_v | $d2_v | $d1_v | $penaltis" >> "$LOG"

                sig_ronda+=("$ganador_elim")
                if [ "$ganador_elim" -eq "$eq1" ]; then
                    perdedor="$eq2"
                else
                    perdedor="$eq1"
                fi

                RONDA[$perdedor]="$R_NOM"
                PESO_RONDA[$perdedor]=$((r_idx + 1))

                if [ "$eq1" -eq "$EQUIPO" -o "$eq2" -eq "$EQUIPO" ]; then
                    echo "*********************************************************"
                    echo "$R_TIT"
                    echo "${EQ_NOM[$eq1]} vs ${EQ_NOM[$eq2]}"
                    echo ""
                    pintar_desglose_partido "IDA" "$eq1" "$eq2" "$g1_i" "$g2_i" "$d1_i" "$d2_i" "$op1_i" "$op2_i" "$p1_i" "$p2_i" "$v1_i" "$v2_i"
                    echo ""
                    pintar_desglose_partido "VUELTA" "$eq2" "$eq1" "$g2_v" "$g1_v" "$d2_v" "$d1_v" "$op2_v" "$op1_v" "$p2_v" "$p1_v" "$v2_v" "$v1_v"
                    echo ""
                    echo "GLOBAL: ${EQ_NOM[$eq1]} $total1 - $total2 ${EQ_NOM[$eq2]}"
                    if [ "$penaltis" != "-" ]; then
                        echo "Penaltis: $penaltis"
                    fi
                    echo "Clasificado: ${EQ_NOM[$ganador_elim]}"
                    echo "*********************************************************"
                    if [ "$perdedor" -eq "$EQUIPO" ]; then jugador_eliminado=1; fi
                fi

            else
                res_fin=$(simular_partido "$eq1" "$eq2" 0 1)
                g1_f=$(echo "$res_fin" | cut -f 1 -d "|"); g2_f=$(echo "$res_fin" | cut -f 2 -d "|")
                d1_f=$(echo "$res_fin" | cut -f 3 -d "|"); d2_f=$(echo "$res_fin" | cut -f 4 -d "|")
                op1_f=$(echo "$res_fin" | cut -f 5 -d "|"); op2_f=$(echo "$res_fin" | cut -f 6 -d "|")
                p1_f=$(echo "$res_fin" | cut -f 7 -d "|"); p2_f=$(echo "$res_fin" | cut -f 8 -d "|")
                v1_f=$(echo "$res_fin" | cut -f 9 -d "|"); v2_f=$(echo "$res_fin" | cut -f 10 -d "|")

                GF[$eq1]=$((GF[$eq1] + g1_f)); GC[$eq1]=$((GC[$eq1] + g2_f))
                GF[$eq2]=$((GF[$eq2] + g2_f)); GC[$eq2]=$((GC[$eq2] + g1_f))

                penaltis="-"
                if [ "$g1_f" -gt "$g2_f" ]; then
                    ganador_elim="$eq1"
                elif [ "$g2_f" -gt "$g1_f" ]; then
                    ganador_elim="$eq2"
                else
                    res_pen=$(simular_penaltis "$eq1" "$eq2")
                    penaltis=$(echo "$res_pen" | cut -f 1 -d "|")
                    ganador_elim=$(echo "$res_pen" | cut -f 2 -d "|")
                fi

                echo "Final | Final | ${EQ_NOM[$eq1]} | ${EQ_NOM[$eq2]} | $g1_f | $g2_f | $d1_f | $d2_f | $penaltis" >> "$LOG"

                if [ "$ganador_elim" -eq "$eq1" ]; then
                    perdedor="$eq2"
                else
                    perdedor="$eq1"
                fi
                RONDA[$perdedor]="Final"
                PESO_RONDA[$perdedor]=4
                RONDA[$ganador_elim]="Campeón"
                PESO_RONDA[$ganador_elim]=5
                campeon_torneo="$ganador_elim"

                if [ "$eq1" -eq "$EQUIPO" -o "$eq2" -eq "$EQUIPO" ]; then
                    echo "*********************************************************"
                    echo "$R_TIT"
                    echo "${EQ_NOM[$eq1]} vs ${EQ_NOM[$eq2]}"
                    echo ""
                    pintar_desglose_partido "FINAL" "$eq1" "$eq2" "$g1_f" "$g2_f" "$d1_f" "$d2_f" "$op1_f" "$op2_f" "$p1_f" "$p2_f" "$v1_f" "$v2_f"
                    echo ""
                    if [ "$penaltis" != "-" ]; then
                        echo "Penaltis: $penaltis"
                    fi
                    echo "Campeón: ${EQ_NOM[$ganador_elim]}"
                    echo "*********************************************************"
                fi
            fi
            i=$((i + 2))
        done

        equipos_jugando=("${sig_ronda[@]}")
        
        if [ "$jugador_eliminado" -eq 0 -a "$R_NOM" != "Final" ]; then
            echo "Pulsa ENTER para pasar a la siguiente ronda: "
            read
        elif [ "$jugador_eliminado" -eq 1 ]; then
            if [ "$R_NOM" != "Final" ]; then
                echo "Simulando el resto del torneo..."
            fi
            jugador_eliminado=2
        fi
    done

    local id=1
    while [ "$id" -le 16 ]; do
        DG[$id]=$(( GF[$id] - GC[$id] ))
        USADO[$id]=0
        id=$((id + 1))
    done

    local pos=1
    while [ "$pos" -le 16 ]; do
        mejor=0
        local cand=1
        while [ "$cand" -le 16 ]; do
            if [ ${USADO[$cand]} -eq 0 ]; then
                if [ "$mejor" -eq 0 ]; then 
                    mejor=$cand
                else
                    cambiar=0
                    if [ ${PESO_RONDA[$cand]} -gt ${PESO_RONDA[$mejor]} ]; then cambiar=1
                    elif [ ${PESO_RONDA[$cand]} -eq ${PESO_RONDA[$mejor]} ]; then
                        if [ ${DG[$cand]} -gt ${DG[$mejor]} ]; then cambiar=1
                        elif [ ${DG[$cand]} -eq ${DG[$mejor]} ]; then
                            if [ ${GF[$cand]} -gt ${GF[$mejor]} ]; then cambiar=1
                            elif [ ${GF[$cand]} -eq ${GF[$mejor]} ]; then
                                pri=$( (echo "${EQ_NOM[$cand]}"; echo "${EQ_NOM[$mejor]}") | sort | head -1 )
                                if [ "$pri" = "${EQ_NOM[$cand]}" ]; then cambiar=1; fi
                            fi
                        fi
                    fi
                    if [ "$cambiar" -eq 1 ]; then mejor=$cand; fi
                fi
            fi
            cand=$((cand + 1))
        done
        USADO[$mejor]=1
        echo "$pos | ${EQ_NOM[$mejor]} | ${RONDA[$mejor]} | ${GF[$mejor]} | ${GC[$mejor]} | ${DG[$mejor]}" >> "$CLASIFICACION"
        pos=$((pos + 1))
    done

    if [ "$campeon_torneo" -eq "$EQUIPO" ]; then
        VICTORIAS=$((VICTORIAS + 1))
        guardar_config
    fi

    echo ""
    echo "========================================="
    echo "      TORNEO FINALIZADO                  "
    echo " Campeón: ${EQ_NOM[$campeon_torneo]}"
    echo " Ronda de ${EQ_NOM[$EQUIPO]}: ${RONDA[$EQUIPO]}"
    echo "========================================="
}

function menu_estadisticas() {
    if [ ! -s "$CLASIFICACION" ] || [ ! -s "$LOG" ]; then
        echo "No hay datos estadísticos. Debes jugar una Champions primero."
        return 0
    fi

    n_clas=$(cat "$CLASIFICACION" | wc -l)
    n_log=$(cat "$LOG" | wc -l)

    campeon_st=""
    finalista_st=""
    ronda_jug_st=""
    max_gf=-1
    max_gc=-1

    local i=1
    while [ "$i" -le "$n_clas" ]; do
        lin=$(head -$i < "$CLASIFICACION" | tail -1)
        nom_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 2)")
        ron_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 3)")
        gf_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 4)")
        gc_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 5)")

        if [ "$ron_c" = "Campeón" ]; then campeon_st="$nom_c"; fi
        if [ "$ron_c" = "Final" ]; then finalista_st="$nom_c"; fi
        if [ "$nom_c" = "${EQ_NOM[$EQUIPO]}" ]; then ronda_jug_st="$ron_c"; fi
        if [ "$gf_c" -gt "$max_gf" ]; then max_gf=$gf_c; fi
        if [ "$gc_c" -gt "$max_gc" ]; then max_gc=$gc_c; fi
        i=$((i + 1))
    done

    echo "**************************************************"
    echo "            ESTADÍSTICAS DEL TORNEO               "
    echo "**************************************************"
    echo " - Campeón: $campeon_st"
    echo " - Finalista: $finalista_st"
    
    echo " - Equipo(s) más goleador(es) [$max_gf goles]:"
    i=1
    while [ "$i" -le "$n_clas" ]; do
        lin=$(head -$i < "$CLASIFICACION" | tail -1)
        nom_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 2)")
        gf_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 4)")
        if [ "$gf_c" -eq "$max_gf" ]; then echo "     * $nom_c"; fi
        i=$((i + 1))
    done

    echo " - Equipo(s) más goleado(s) [$max_gc goles]:"
    i=1
    while [ "$i" -le "$n_clas" ]; do
        lin=$(head -$i < "$CLASIFICACION" | tail -1)
        nom_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 2)")
        gc_c=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 5)")
        if [ "$gc_c" -eq "$max_gc" ]; then echo "     * $nom_c"; fi
        i=$((i + 1))
    done

    echo " - Ronda de tu equipo (${EQ_NOM[$EQUIPO]}): $ronda_jug_st"

    max_g_partido=-1
    c_dec=(0 0 0 0)
    tot_pen=0

    i=1
    while [ "$i" -le "$n_log" ]; do
        lin=$(head -$i < "$LOG" | tail -1)
        g_a=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 5)")
        g_b=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 6)")
        d_a=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 7)")
        d_b=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 8)")
        pen=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 9)")

        suma=$((g_a + g_b))
        if [ "$suma" -gt "$max_g_partido" ]; then max_g_partido=$suma; fi
        if [ "$pen" != "-" ]; then tot_pen=$((tot_pen + 1)); fi

        local k
        for k in 0 1 2 3; do
            if [ "$d_a" = "${DEC_NOM[$k]}" ]; then c_dec[$k]=$((c_dec[$k] + 1)); fi
            if [ "$d_b" = "${DEC_NOM[$k]}" ]; then c_dec[$k]=$((c_dec[$k] + 1)); fi
        done
        i=$((i + 1))
    done

    echo " - Partido(s) con más goles [$max_g_partido goles en total]:"
    i=1
    while [ "$i" -le "$n_log" ]; do
        lin=$(head -$i < "$LOG" | tail -1)
        ron=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 1)")
        par=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 2)")
        eq_a=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 3)")
        eq_b=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 4)")
        g_a=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 5)")
        g_b=$(limpiar_espacios "$(echo "$lin" | cut -d "|" -f 6)")
        suma=$((g_a + g_b))
        if [ "$suma" -eq "$max_g_partido" ]; then
            echo "     * $ron ($par): $eq_a $g_a - $g_b $eq_b"
        fi
        i=$((i + 1))
    done

    max_freq=-1
    local k
    for k in 0 1 2 3; do
        if [ "${c_dec[$k]}" -gt "$max_freq" ]; then
            max_freq=${c_dec[$k]}
        fi
    done

    echo " - Decisión más frecuente [$max_freq apariciones]:"
    for k in 0 1 2 3; do
        if [ "${c_dec[$k]}" -eq "$max_freq" ]; then
            echo "     * ${DEC_NOM[$k]}"
        fi
    done

    echo " - Eliminatorias decididas por penaltis: $tot_pen"
    echo "**************************************************"
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
            ;;
        E|e)
            menu_estadisticas
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