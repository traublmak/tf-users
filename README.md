# Постановка задачи
Есть ~20 самостоятельных аккаунтов AWS  
Нужно упростить управление пользователями в любом из этих аккаунтом:
- создать IAM группу с определенными Policy (Доступ к vpc, ec2, s3, eks, cloudwatch, iam политики)
- Создать пользователя (или несколько пользователей по списку usernames) в любом из множества аккаунтов (с консольным доступом, с программным доступом), добавить в уже существующую группу

# Подготовка
### 1. Установить terraform
https://www.terraform.io/downloads.html  
Скачать бинарник, распаковать в папку system's PATH

### 2. Установить KeyBase и сгенерировать ключи
Скачать и установить - https://keybase.io/download  
Сгенерировать ключ: 
```bash
# Генерация (при генерации выбрать опцию "выгрузить на публичный сервер")
keybase pgp gen
#Запомнить имя ключа или получить в консоли:
keybase id
```
Подставить в файл users.tfvars в 
pgp_key = "keybase:KEY_NAME"


### 3. Создать в аккаунтах AWS роли и настроить доступ для "корневого" аккаунт 
https://learn.hashicorp.com/tutorials/terraform/aws-assumerole?in=terraform/aws  
Выбираем аккаунт MAIN, из которого будем управлять другими аккаунтами.  
Для примера рассмотрим пару аккаунтов - MAIN и accountA, чтобы разобраться, что нужно настроить.  
в MAIN создаем аккаунт (или выбираем существующий) с программным доступом для работы Terraform - пусть это будет userMain

Согласно руководству AWS настроить Delegate access across AWS accounts
https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html  
учитывая, что Production в мане это MAIN, Development  - это AccountA

#### Кратко, что нужно сделать:
1) Создать роль в AccountA с разрешениями для юзера из MAIN аккаунта:  
При создании роли указать <b>Another AWS Account:</b> Main Account ID  
Добавить Permissions, необходимые для выполнения задач.  
Если предполагается только управлениями аккаунтами, то политики IAMFullAccess будет достаточно

Сохранить (записать) arn созданной роли. Он будет использован дальше.  

Повторить во всех аккаунтов, которыми нужно управлять из MAIN

2) В MAIN аккаунте назначить пользователю userMain, под которым будем подключаться к др. аккаунтам, разрешение на подключение к ним.  
Для этого создать политику по примеру ниже, подставить в нее ARN роли из п. 1 и назначить эту роль нашему пользователю в MAIN
```yaml
 {
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["sts:AssumeRole"],
    "Resource": "arn:aws:iam::accountA-ID:role/RoleInAccountA"
  }]
}
```
Можно расширить Recources для нескольких аккаунтов:
```yaml
 "Resource": [
        "arn:aws:iam::accountA-ID:role/RoleInAccountA",
        "arn:aws:iam::accountB-ID:role/RoleInAccountB"
      ]
```
Подготовка завершена

#  Добавление аккаунтов
### Установить переменные
В users.tfvars установить переменные:  
- **iam_users** - список имен пользователей, 
- **group** - название группы, которую нужно создать или существующей
- **pgp_key** - ссылка на ключ в Keybase
- **create_login_profiles** = true/false = создать доступ к web-консоли для пользователей
- **create_access_keys** = true/false  = создать программный доступ (access keys)

- Проверить и при необходимости скорректировать список Policy для группы, которая будет создана.   
Это файл main.tf, module "iam_group_students", custom_group_policy_arns

### Залогиниться в AWS 
Варианты:
- Залогиниться в AWS cli под учеткой userMain из аккаунта MAIN (_aws configure_)
- Или прописать access_key и secret_key в main.tf   (раскомментировав раздел "авторизация напрямую в iAWS provider" в **main.tf**)
Подробнее про аутентификацию в AWS в документации terraform:  
https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication

### Добавить assume role
В скрипте **main.tf** установить роль, под которой будет выполнятся подключение к другим аакаунтам:  
в разделе **assume_role** установить ARN роли, который был создан в предыдущих шагах в AccountA

### Запускаем скрипт
```bash
# Из папки со скриптами:
### Инициализировать terraform, запустить один раз
terraform init
### Проверить скрипты и конфиг terraform (ничего не применяется)
terraform plan -var-file="users.tfvars"
### Запуск на выполнение
terraform apply -var-file="users.tfvars"
```
## Разбираемся в выводе после apply
После того, как скрипт выполнен, получаем список пользователей с атрибутами - пароль для консоли (если создавался), access_key, secret_key   
Пароли зашифрованы pgp ключом, поэтому в листинге получаем команду для расшифровки вида:
```bash
password_decrypt_command = "echo 'ENCRYPTED-KEY' | base64 --decode -i | keybase pgp decrypt
```
Стоит иметь ввиду, что для этого нужна утилита base64.   
В Linux она чаще уже есть, в Windows нет. Для Win можно использовать base64.exe из Git - https://git-scm.com/download/win  
C:\Program Files\Git\usr\bin\base64.exe - будет установлена в эту папку для x64