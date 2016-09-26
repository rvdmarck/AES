import serial
import codecs
from time import sleep
import time

ser = serial.Serial("/dev/ttyACM0", baudrate=9600, timeout=2)


print(ser.read().decode("utf-8"))


text = "101112131415161718191A1B1C1D1E1F\n"
text = text[:32]
text_ascii = codecs.decode(text, "hex")

start_time = time.time()

ser.write(text_ascii)
ret = codecs.encode(ser.read(16), "hex").decode("utf-8").upper()
print("Execution Time: "+str(time.time()-start_time))
print("CipherText: " + ret)
