file 文件对象使用 open 函数来创建，下表列出了 file 文件对象常用的函数：

| 序号  | 方法及描述                                                                                                                                                                            |
| --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | [file.close()](https://www.w3cschool.cn/python3/python3-file-close.html)<br><br>关闭文件。关闭后文件不能再进行读写操作。                                                                             |
| 2   | [file.flush()](https://www.w3cschool.cn/python3/python3-file-flush.html)<br><br>刷新文件内部缓冲，直接把内部缓冲区的数据立刻写入文件, 而不是被动的等待输出缓冲区写入。                                                     |
| 3   | [file.fileno()](https://www.w3cschool.cn/python3/python3-file-fileno.html)<br><br>返回一个整型的文件描述符 (file descriptor FD 整型), 可以用在如 os 模块的 read 方法等一些底层操作上。                            |
| 4   | [file.isatty()](https://www.w3cschool.cn/python3/python3-file-isatty.html)<br><br>如果文件连接到一个终端设备返回 True，否则返回 False。                                                               |
| 5   | [file.next()](https://www.w3cschool.cn/python3/python3-file-next.html)<br><br>返回文件下一行。                                                                                           |
| 6   | [file.read([size])](https://www.w3cschool.cn/python3/python3-file-read.html)<br><br>从文件读取指定的字节数，如果未给定或为负则读取所有。                                                                   |
| 7   | [file.readline([size])](https://www.w3cschool.cn/python3/python3-file-readline.html)<br><br>读取整行，包括 "\n" 字符。                                                                     |
| 8   | [file.readlines([sizehint])](https://www.w3cschool.cn/python3/python3-file-readlines.html)<br><br>读取所有行并返回列表，若给定 sizeint>0，返回总和大约为 sizeint 字节的行, 实际读取值可能比 sizeint 较大, 因为需要填充缓冲区。 |
| 9   | [file.seek(offset[, whence])](https://www.w3cschool.cn/python3/python3-file-seek.html)<br><br>设置文件当前位置                                                                           |
| 10  | [file.tell()](https://www.w3cschool.cn/python3/python3-file-tell.html)<br><br>返回文件当前位置。                                                                                          |
| 11  | [file.truncate([size])](https://www.w3cschool.cn/python3/python3-file-truncate.html)<br><br>截取文件，截取的字节通过 size 指定，默认为当前文件位置。                                                      |
| 12  | [file.write(str)](https://www.w3cschool.cn/python3/python3-file-write.html)<br><br>将字符串写入文件，返回的是写入的字符长度。                                                                         |
| 13  | [file.writelines(sequence)](https://www.w3cschool.cn/python3/python3-file-writelines.html)<br><br>向文件写入一个序列字符串列表，如果需要换行则要自己加入每行的换行符。                                             |
