#!/bin/bash




if [ "$1" = "-g" ]; then
    echo "******************************"
    echo            DEV TEAM
    echo "******************************"
    echo "     Daniel Sánchez Salvador  "
    echo "     Juan Peguero García      "
    echo " Sistemas Operativos I - PB3  "
    echo "******************************"
    exit 0
fi


CONFIG="../cfg/config.cfg"
EQUIPOS="../cfg/equipos.cfg"
DECISIONES="../cfg/decisiones.cfg"

if [ ! -f "$CONFIG" ] || [  ! -f "$EQUIPOS" ] || [ ! -f "$DECISIONES" ]; then
    echo "Faltan archivos clave de configuración"
    exit 1
fi


###FUNCIONES AUXILIARES DE CONFIGURACION

function get_config_val(){
    key="$1"
    grep "^${key}=" "$CONFIG" | cut -d'=' -f2- #esto busca la linea que empiece por "nombre" y luego extrae el valor detras del =
}

function cargar_config(){
    NOMBRE=$(get_config_val "NOMBRE")
    EQUIPO=$(get_config_val "EQUIPO")
    VICTORIAS=$(get_config_val "VICTORIAS")
    LOG=$(get_config_val "LOG")
    CLASIFICACION=$(get_config_val "CLASIFICACION")
}

cargar_config

function guardar_config(){
    echo "NOMBRE=$NOMBRE" > "$CONFIG"
    echo "EQUIPO=$EQUIPO" >> "$CONFIG"
    echo "VICTORIAS=$VICTORIAS" >> "$CONFIG"
    echo "LOG=$LOG" >> "$CONFIG"
    echo "CLASIFICACION=$CLASIFICACION" >> "$CONFIG"

}


###MOSTRAR_MENU_CONFIG
menu_config(){

    while true; do
        echo ""
        echo "*****************MENÚ DE CONFIGURACIÓN*****************"
        echo "1) Nombre del jugador: ${NOMBRE:-[No configurado]}"
        echo "2) Equipo seleccionado (ID): ${EQUIPO:-[No seleccionado]}"
        echo "3) Archivo de LOG: ${LOG}"
        echo "4) Archivo de CLASIFICACION: ${CONFIG}"
        echo "5) Salir de configuración"
        echo "*******************************************************"
        echo ""

        read -p "Seleccione una opción (1-5): " opt_c

        case "$opt_c" in

            1) 
                read -p "Ingrese nuevo nombre: " new_nom
                if [ -n "$new_nom" ]; then
                    NOMBRE="$new_nom"
                    guardar_config
                    echo "Nombre actualizado a: " $NOMBRE
                else
                    echo "El nombre no puede estar vacío"
                fi
                ;;
            2)  read -p "Introduzca el ID del equipo: " new_id
                if [ -n "$new_id" ]; then
                    EQUIPO="$new_id"
                    guardar_config
                    echo "El ID del Equipon ha sido actualizado a: " $new_id
                else
                    echo "Error al actualizar el nombre"
                fi
                ;;
            3)
                read -p "Ingrese la nueva ruta donde almacenar los partidos: " new_log
                if [ -n "$new_log" ]; then
                    LOG="$new_log"
                    guardar_config
                    echo "La ruta ha cambiado a: " $new_log
                else
                    echo "La ruta está vacía"
                fi
                ;;
            4)  read -p "Ingrese la nueva ruta donde almacenarán las clasificaciones: " new_clas
                if [ -n "$new_clas"]; then
                    CLASIFICACION="$new_clas"
                    guardar_config
                    echo "La ruta ha cambiado a: " $new_clas
                else
                    echo "La ruta está vacía o no es válida"
                fi
                ;;
            5)  echo "SALIENDO..."
                
                ;;
            esac    
    done
}

menu_config #esto no va aqui, es para depuarar el menu

