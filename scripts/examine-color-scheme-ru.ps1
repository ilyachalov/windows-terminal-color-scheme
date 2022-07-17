#
#   Скрипт проверяет в заданной цветовой схеме наличие необходимых полей
#   и валидность значений цветов, записанных в поля. Основные проверки:
#   нет ли в схеме полей с одинаковыми значениями цветов, нет ли в схеме
#   пар цветовых полей с контрастностью ниже заданного критерия
#   (по умолчанию критерий равен 1.1).
#
#   Цветовая схема задается в отдельном файле в формате JSON. Имя этого
#   файла следует передать скрипту в параметре. Пример запуска скрипта:
#   > .\examine-color-scheme-ru campbell.jsonc
#
#   Формат описания цветовой схемы в файле JSON описан тут:
#   https://docs.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes
#

param ($file = $(throw "Ошибка: задайте в параметре название файла с цветовой схемой!"))
""

$colorScheme = get-content $file | convertfrom-json

if ($null -eq $colorScheme.name) {
    "Цветовая схема: <название не указано> (отсутствует поле 'name')"
} else {
    "Цветовая схема: $($colorScheme.name)"
}
"--------------------------------------------------"

$arrFields = "black", "red", "green", "yellow", "blue", "purple", "cyan", "white",
             "brightBlack", "brightRed", "brightGreen", "brightYellow",
             "brightBlue", "brightPurple", "brightCyan", "brightWhite",
             "foreground", "background",
             "cursorColor", "selectionBackground"

#   Проверка наличия полей в цветовой схеме и выдача предупреждений
$ok = 1
foreach ($field in $arrFields) {
    if ($null -eq $colorScheme.$field) {
        $ok = 0
        "Предупреждение: в цветовой схеме отсутствует поле '$field'!"
    }
}
if ($ok) {
    "В цветовой схеме есть все необходимые поля."
}
""

#   Проверка значений цветов на валидность
$ok = 1
foreach ($field in $arrFields) {
    if ($null -ne $colorScheme.$field) {
        #   Валидно либо значение цвета с 6 шестнадцатеричными цифрами,
        #   либо значение цвета с 3 шестнадцатеричными цифрами.
        if ($colorScheme.$field -notmatch '^#([0-9A-F]{3}){1,2}$') {
            "Ошибка: невалидное значение цвета в поле '$field': '$($colorScheme.$field)'!"
            $ok = 0
        } elseif ($colorScheme.$field -match '^#[0-9A-F]{3}$') {
            #   Значение цвета валидно, но состоит из 3 шестнадцатеричных цифр
            $old = $colorScheme.$field
            $colorScheme.$field = $old[0] + $old[1] + $old[1] + $old[2] +
                                            $old[2] + $old[3] + $old[3]
            "Предупреждение: значение цвета '$old' в поле '$field' считаю " +
            "за '$($colorScheme.$field)'!"
        }
    }
}
if ($ok) {
    "Все значения цветов, заданные для полей цветовой схемы, валидны."
} else {
    "Исправьте указанные ошибки. Скрипт прерывает работу.`n"
    return
}
""

#   Проверка: нет ли полей с одинаковыми значениями цветов
$ok = 1
for ($i = 0; $i -lt $arrFields.Count; $i++) {
    $field1 = $arrFields[$i]
    #   Если поле $field1 существует
    if ($null -ne $colorScheme.$field1) {
        #   Сравниваем поле $field1 со всеми последующими в массиве, кроме себя
        for ($j = $i + 1; $j -lt $arrFields.Count; $j++) {
            $field2 = $arrFields[$j]
            #   Если поле $field2 существует
            if ($null -ne $colorScheme.$field2) {
                #   При совпадении значений цветов в полях
                if ($colorScheme.$field1 -eq $colorScheme.$field2) {
                    "Совпадает значение цвета в полях '$field1' и '$field2': '$($colorScheme.$field1)'!"
                    $ok = 0
                }
            }
        }
    }
}
if ($ok) {
    "В этой цветовой схеме нет полей с одинаковыми значениями цветов."
}
""

#   Функция получает цвет в виде строки "#fa7014" и возвращает
#   относительную яркость этого цвета (значение в диапазоне от 0 до 1)
function get-relative-luminance($RGB) {
    #   sRGB
    $sRGB = 0, 0, 0
    $sRGB[0] = ([int]("0x" + $RGB[1] + $RGB[2])) / 255
    $sRGB[1] = ([int]("0x" + $RGB[3] + $RGB[4])) / 255
    $sRGB[2] = ([int]("0x" + $RGB[5] + $RGB[6])) / 255

    #   Вспомогательная функция (получает число, возвращает число)
    function get-linear($param) {
        $val = $param
        if ($val -lt 0.03928) {
            $val = $val / 12.92
        } else {
            $val = [Math]::Pow((($val + 0.055) / 1.055), 2.4)
        }
        return $val
    }

    #   linear RGB
    $sRGB[0] = get-linear $sRGB[0]
    $sRGB[1] = get-linear $sRGB[1]
    $sRGB[2] = get-linear $sRGB[2]

    #   Возврат числа, характеризующего относительную яркость
    return $sRGB[0] * 0.2126 + $sRGB[1] * 0.7152 + $sRGB[2] * 0.0722
}

#   Проверка контрастности всех пар цветов на соответствие критерию
$criteria = 1.1   #   В диапазоне от 1 (1:1) до 21 (21:1)
$ok = 1
for ($i = 0; $i -lt $arrFields.Count; $i++) {
    $field1 = $arrFields[$i]
    #   Если поле $field1 существует
    if ($null -ne $colorScheme.$field1) {
        #   Сравниваем поле $field1 со всеми последующими в массиве, кроме себя
        for ($j = $i + 1; $j -lt $arrFields.Count; $j++) {
            $field2 = $arrFields[$j]
            #   Если поле $field2 существует
            if ($null -ne $colorScheme.$field2) {
                #   При совпадении значений цветов в полях ничего не сообщать,
                #   так как это уже было сделано ранее (не стоит дублировать предупреждения)
                if ($colorScheme.$field1 -eq $colorScheme.$field2) {
                    $ok = 0
                } else {
                    #   Вычисление относительной яркости каждого цвета
                    $L1 = get-relative-luminance $colorScheme.$field1
                    $L2 = get-relative-luminance $colorScheme.$field2
                    #   Вычисление контрастности более яркого цвета относительно
                    #   более темного цвета
                    $Cr = 0
                    if ($L1 -gt $L2) {
                        $Cr = ($L1 + 0.05) / ($L2 + 0.05)
                    } else {
                        $Cr = ($L2 + 0.05) / ($L1 + 0.05)
                    }
                    #   Проверка соответствия контрастности критерию
                    if ($Cr -lt $criteria) {
                        "Контрастность цветов в поле '$field1' и в поле '$field2' меньше " +
                        "$criteria`: $([Math]::Round($Cr, 5))!"
                        if ($L1 -gt $L2) {
                            "   пример: $($PSStyle.Foreground.FromRgb($colorScheme.$field1))" +
                            "$($PSStyle.Background.FromRgb($colorScheme.$field2)) " +
                            "Тестовый текст $($PSStyle.Reset) ('$field1' на '$field2')"
                        } else {
                            "   пример: $($PSStyle.Foreground.FromRgb($colorScheme.$field2))" +
                            "$($PSStyle.Background.FromRgb($colorScheme.$field1)) " +
                            "Тестовый текст $($PSStyle.Reset) ('$field2' на '$field1')"
                        }
                        $ok = 0
                    }
                }
            }
        }
    }
}
if ($ok) {
    "В этой цветовой схеме нет пар полей с контрастностью цветов меньше $criteria."
}
""