#
#   Этот скрипт выводит в терминал таблицу цветов,
#   такую же, как на сайте компании «Microsoft»:
#   https://docs.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes
#
#   Я не нашел исходник скрипта, который там использовали,
#   поэтому написал (2022 г.) вот этот вот свой вариант.
#
#   Добавление (18x9): я добавил к исходной таблице 2 строки
#   для ESC[49m (цвет фона «по умолчанию») и колонку для
#   ESC[39m и ESC[1;39m (цвет текста «по умолчанию»). В итоге
#   получилась таблица цветов размером 18x9. (Исходная таблица
#   имела размер 16x8.)
#

$Esc = [char]27   # Работает в «Windows PowerShell» версии 5.1

"`nBackground | Foreground colors"
$hr = "----------------------------------------------------------------------------"
"$hr"

foreach ($BG in "49", "40", "41", "42", "43", "44", "45", "46", "47") {
    write-host " ESC[$BG`m   | " -NoNewline
    foreach ($FGs in "39m  ", "30m  ", "31m  ", "32m  ", "33m  ",
                     "34m  ", "35m  ", "36m  ", "37m  ") {
        $FG = $FGs -replace " ", ""
        write-host "$Esc[$BG`m $Esc[$FG[$FGs$Esc[0m" -NoNewline
    }
    ""
    write-host " ESC[$BG`m   | " -NoNewline
    foreach ($FG in "1;39m", "1;30m", "1;31m", "1;32m", "1;33m",
                    "1;34m", "1;35m", "1;36m", "1;37m") {
        write-host "$Esc[$BG`m $Esc[$FG[$FG$Esc[0m" -NoNewline
    }
    "`n$hr"
}
""