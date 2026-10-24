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
                if [ -n "$nuevo_nom" ]; then
                    
    done
        

    
}

