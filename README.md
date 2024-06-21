# О проекте

    Этот проект является рабочим столом разработчика репозитория deb пакетов и одновременно местом публикации репозитория через github-pages.

## Состав проекта:

`/doc` – каталог с документацией.

`/apt-repo` – каталог опубликованный через github-pages с собственно deb репозиторием. Содержимое каталога доступно по адресу https://tegho.github.io/small_office_vpn/apt-repo

`/keys` – каталог с ключами для подписания deb репозитория. Закрытый ключ внесен в gitignore и не публикуется.

`/packages` – каталог с исходными данными пакетов и инструментами для их компиляции.

`/utils` – каталог с полезными утилитами.

`/vars` – файл настроек репозитория.

## Перечень документации

[README.dev.md](doc/README.dev.md) – информация для разработчика deb репозитория.

[README.skillbox.md](doc/README.skillbox.md) – учебный проект Skillbox Старт в DevOps.

[README.ajalo.admin.md](doc/README.ajalo.admin.md) – инструкция администратора проекта ajalo.

[README.ajalo.user.md](doc/README.ajalo.user.md) – инструкция пользователя проекта ajalo.

[README.packages.md](doc/README.packages.md) – описание пакетов репозитория.
