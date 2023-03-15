# mestrado-qemu-kernel-busybox

Este repositório tem o intuito de abrigar o passo a passo para a criação dos artefatos necessários para as máquinas virtuais a serem utilizadas na Disciplina de Redes Veiculares e Industriais do programa de Mestrado PPGCC na UFSC.

Objetivo ter máquinas virtuais compactas rodando sobre o software QEMU.

## Intalação QEMU

	sudo apt-get update
	sudo apt-get install git fakeroot build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison qemu-system-x86

## Build Kernel

O QEMU consegue redar ambientes virtuais de diversas formas, inclusive emulando cd-roms com imagens ISO.

Porém, o intuito da disciplina é testar diferentes configurações de redes, para tal a ideia é montar uma máquina que seja leve e que tenha apenas o mínimo de coisas necessárias.

Dessa forma, vamos compilar apenas o Kernel do Linux.

### Obtendo os códigos

	wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.15.57.tar.xz
	tar xvf linux-5.15.57.tar.xz
	cd linux-5.15.57

### Configurando o build

Para tal, vamos precisar criar algumas configurações:

	make defconfig
	make kvm_guest.config

Além disso, é importante verificar algumas configurações:

	make menuconfig

* [*] 64-bit kernel

* General setup --->

	* [?] System V IPC

	* [*] Initial RAM filesystem and RAM disk (initramfs/initrd) support

	* Configure standard kernel features (expert users) --->

		* [?] Sysfs syscall support

		* [*] Enable support for printk

		* [?] BUG() support

		* [?] Enable ELF core dumps

	* [?] Load all symbols for debugging/ksymoops

	* [?] Disable heap randomization

	* [?] Profiling support

* Executable file formats --->

	* [*] Kernel support for ELF binaries

	* [*] Kernel support for scripts starting with #!

* Device Drivers --->

	* [*] Block devices --->

		* [*] RAM block device support

	* Character devices --->

		* [*] Enable TTY

		* Serial drivers --->

			* [*] 8250/16550 and compatible serial support

			* [*] Console on 8250/16550 and compatible serial port

* File systems --->

	* Pseudo filesystems --->

		* [*] /proc file system support

		* [*] sysfs file system support

* Kernel hacking --->

	* Compile-time checks and compiler options --->

		* [*] Compile the kernel with debug info

		* [*] Provide GDB scripts for kernel debugging

	* Generic Kernel Debugging Instruments --->

		* [*] Debug filesystem

		* [*] KGDB: kernel debugger

	* x86 Debugging --->

		* [*] Early printk

Depois de salvo, podemos verficiar se está ok da seguinte forma:

	cat .config | grep KVM

O resultado deve ser algo assim:

	CONFIG_KVM_GUEST=y
	# CONFIG_KVM_DEBUG_FS is not set
	CONFIG_HAVE_KVM=y
	# CONFIG_KVM is not set
	CONFIG_PTP_1588_CLOCK_KVM=y

### Building Kernel

Utilizamos o comando make para compilar o kernel

	make -j`nproc`

Isso pode levar alguns bons minutos, no final você deverá ter uma imagem do kernel (bzImage)

	ls arch/x86/boot/bzImage

## Preparando o sistema de arquivos

Para o Kernel poder bootar, será necessário um sistema de arquivos, isso pode ser feito de diversas formas. VOcê pode criar uma partição com algum sistema de arquivos por exemplo. 

Neste caso, é necessário que seja leve e que tenha apenas o que é necessário, por isso vamos usar o initramfs. Isso é um arquivo compactado no formato CPIO que é extraído quando o kernel é inicializado (boot). Com isso, conseguimos bootar o Kernel de modo seguro e sem precisar de todo um disco com sistemas de arquivos e etc.

Para isso podemos simplesmente começar com um arquivo simples, ou ainda adicionar algumas coisas para nos ajudar. Aqui vamos usar o initramfs com Busybox.

### Busybox


#### Download 

Primeiro, fazemos o download, semelhante ao kernel:

	wget https://busybox.net/downloads/busybox-1.36.0.tar.bz2
	tar xvf busybox-1.36.0.tar.bz2
	cd busybox-1.36.0.tar.bz2

Aqui, também precisamos configurar o build

#### Configuração

	make menuconfig

Settings --->

--- Build Options

* [*] Build static binary (no shared libs)

--- Debugging Options

* [*] Build with debug information

* [*] Disable compiler optimizations

#### Compilando

	make
	make install

Isso criará uma pasta chamada _install que conterá a estrutura do Busybox que será posteriormente inserida na imagem do initramfs

## Boot do Kernel com initramfs

Para tal, o próprio Kernel nos oferece um aplicativo para construção da imagem:

	usr/gen_initramfs.sh

Para podermos utilizar essa ferramenta, precisaremos de um arquivo cpio_list. Para tal vamos considerar a seguinte estrutura:

	/ --x-- linux-5.15.57/
		|
		x-- busybox-1.36.0/
		|
		x-- cpio_list

O arquivo cpio_list podemos preenher com o seguinte conteúdo:

	dir /dev 0755 0 0
	nod /dev/console 0600 0 0 c 5 1
	dir /root 0700 0 0

	nod /dev/null 0666 0 0 c 1 3
	nod /dev/zero 0666 0 0 c 1 5

	dir /proc 0755 0 0
	dir /sys  0755 0 0
	dir /mnt  0755 0 0

	file /init ./init.sh 0755 0 0

Além disso, precisamos criar o arquivo init.sh descrito no cpio_list, neste arquivo poderemos executar códigos que queremos que sejam executados na inicialização da máquina

	#!/bin/sh

	echo -e "\nhello, busybox!\n"

	mount -t proc none /proc
	mount -t sysfs none /sys
	# mount -t debugfs none /sys/kernel/debug
	
	echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"
	
	sh

Este arquivo, salvamos dentro da pasta linux-5.15.57

Agora vamos gerar o iniramfs:

	cd ./linux-5.15.57/
	./usr/gen_initramfs.sh -o ../initramfs.img ../busybox-1.36.0/_install ../cpio_list

Deverá ter criado um arquivo chamado initramfs.img no diretório raíz do projeto.

## Fazer boot do QEMU com Kernel e Initramfs

Dentro do diretório do projeto, rodamos o seguinte comando para criação de uma simples VM com o Kernel que compilamos e a imagem do initramfs que geramos

	qemu-system-x86_64 -m 512M -kernel linux-5.15.57/arch/x86/boot/bzImage -initrd initramfs.img -enable-kvm -append "console=ttyS0 root=/dev/ram init=/init" -nographic

Para rodar uma máquina com as informações solicitadas:

	qemu-system-x86_64 -m 512M -kernel linux-5.15.57/arch/x86/boot/bzImage -initrd initramfs.img -enable-kvm -append "console=ttyS0 root=/dev/ram init=/init" -nographic -netdev socket,id=vlan0,mcast=230.0.0.1:1234 -device pcnet,id=eth0,netdev=vlan0,mac=56:34:12:00:54:08

## Referências

1. Compilação de Kernel
https://vccolombo.github.io/cybersecurity/linux-kernel-qemu-setup/

2. Busybox
https://blog.jm233333.com/linux-kernel/build-and-run-a-tiny-linux-kernel-on-qemu/#boot-on-qemu-with-initramfs
