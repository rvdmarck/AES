#include "aes.h"


void subWord(uint8_t* words)
{
	/*substitute words with a sbox matrix*/
	words[0] = getSboxVal(words[0]);
    words[1] = getSboxVal(words[1]);
    words[2] = getSboxVal(words[2]);
    words[3] = getSboxVal(words[3]);
}

void rotWord(uint8_t* words)
{
	/*single left rotation of the words array*/
	uint8_t tmpVal = words[0];
	words[0] = words[1];
	words[1] = words[2];
	words[2] = words[3];
	words[3] = tmpVal;
}


uint8_t getSboxVal(uint8_t i)
{
	return sBox[i];
}

void keyExpansion(void)
{
	/* routine that initalizes roundKey array*/
	uint32_t i,j;
	uint8_t tmp[4];

	/*first round is cipherKey itself*/
	for(i = 0; i<nk; ++i)
	{
		keyExpansionUtility(roundKey, cipherKey, i);
	}
	

	/*fors rounds > 3:*/
	while(i<(nb*(nr+1)))
	{
		for(j=0; j<4; ++j)
		{
			tmp[j] = roundKey[(i-1)*4 + j];
		} 

		if(i%nk == 0)
		{
			rotWord(tmp);
			subWord(tmp);
			tmp[0] = tmp[0] ^ rCon[i/nk];
		}

		else if (nk>6 && i%nk ==4)
		{
			subWord(tmp);
		}
		keyExpansionUtility2(roundKey, tmp, i);
		i++;
	}	
}


void keyExpansionUtility(uint8_t* roundKey, const uint8_t* arr, uint32_t i)
{
	uint8_t j;
	for(j=0; j<nk; ++j)
	{
		roundKey[i*nk+j] = arr[i*nk+j];
	}
}

void keyExpansionUtility2(uint8_t* roundKey, uint8_t* arr, uint32_t i)
{
	uint8_t j;
	for(j=0; j<nk; ++j)
	{
		roundKey[i*nk+j] = roundKey[(i-nk)*nk+j]^arr[j];
	}
}


void addRoundKey(uint8_t round_)
{
	uint8_t i,j;
	for(i=0; i<nk; ++i)
	{
		for(j=0; j<nk; ++j)
		{
			state[i][j] ^= roundKey[round_*nb*4 + i*nb + j];
		}
	}
}


void shiftRows(void)
{
	uint8_t tmp;
	/*1re ligne : 1 rot à gauche*/
	tmp = state[0][1];
	state[0][1] = state [1][1];
	state[1][1] = state [2][1];
	state[2][1] = state [3][1];
	state[3][1] = tmp;

	/*2eme ligne : 2 rot*/
	tmp = state[0][2];
	state[0][2] = state[2][2];
	state[2][2] = tmp;

	tmp = state[1][2];
	state[1][2] = state[3][2];
	state[3][2] = tmp;

	/*3eme ligne : 3 rot*/
	tmp = state[0][3];
	state[0][3] = state[3][3];
	state[3][3] = state[2][3];
	state[2][3] = state[1][3];
	state[1][3] = tmp;

}

void subBytes(void)
{
	uint8_t i,j;
	for(i=0; i<nk; ++i)
	{
		for(j=0; j<nk; ++j)
		{
			state[i][j] = getSboxVal(state[i][j]);
		}
	}
}

uint8_t xtime(uint8_t x)
{
	return ((x<<1)^(((x>>7)&1)*0x1b));
}

void mixColumns(void)
{
	uint8_t i, t, tm, tmp;

	for (i=0; i<nk; ++i)
	{
		t = state[i][0];
		tmp = state[i][0] ^ state[i][1] ^ state[i][2] ^ state[i][3];

		tm = state[i][0] ^ state[i][1];
		tm = xtime(tm);
		state[i][0] ^= tm^tmp;

		tm = state[i][1] ^ state[i][2];
		tm = xtime(tm);
		state[i][1] ^= tm^tmp;

		tm = state[i][2] ^ state[i][3];
		tm = xtime(tm);
		state[i][2] ^= tm^tmp;

		tm = state[i][3] ^ t;
		tm = xtime(tm);
		state[i][3] ^= tm^tmp;

	}
}

void cipher(void)
{
	initState();
	uint8_t round = 0;
	addRoundKey(0);

	for (round = 1; round<nr; ++round)
	{
		subBytes();
		shiftRows();
		mixColumns();
		addRoundKey(round);
	}

	subBytes();
	shiftRows();
	addRoundKey(nr);

	printState(); //=output
}

void initState(void)
{
	uint8_t i,j;
	//init de state avec input
	for (i=0;i<4;++i)
	{
		for(j=0;j<4;++j)
		{
			state[i][j] = input[4*i +j];
		}
	}
}

void printState(void)
{
	uint8_t i,j;
	for (i=0;i<4;++i)
	{
		for(j=0;j<4;++j)
		{
			printf("%02x ",state[j][i]);
		}
		printf("\n");
	}
	printf("\n");
}