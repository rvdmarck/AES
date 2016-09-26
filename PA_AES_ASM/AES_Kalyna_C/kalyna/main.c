#include "aes.h"

int main(void)
{
	keyExpansion();
	cipher();
	printf("Cipher text : \n"); 
	displayArray(state);
	return 0;
}
