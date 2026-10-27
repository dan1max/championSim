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
            # BORRAR COMENTARIO: Aquí se llama a la función jugar_champions cuando la tengamos
            echo "Opción Jugar Champions"
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