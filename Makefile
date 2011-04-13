CC = clang -framework Foundation -fobjc-gc-only
all_targets = fact watch fun nofun

all: $(all_targets)

compile:
	$(CC) -o $(target) $(target).m

fact:
	$(MAKE) compile target=fact

watch:
	$(MAKE) compile target=watch 

fun:
	$(MAKE) compile target=fun

nofun:
	$(MAKE) compile target=nofun
