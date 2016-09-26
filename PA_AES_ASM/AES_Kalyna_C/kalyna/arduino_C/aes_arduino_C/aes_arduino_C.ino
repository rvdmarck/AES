#include "aes.h"

void generateIntermediateKey(uint8_t* kt)
{
	uint8_t k1 [sizeof(uint64_t) * nb];
	uint8_t k0 [sizeof(uint64_t) * nb];

	memcpy(k0, cipherKey, nb * sizeof(uint64_t));
	memcpy(k1, cipherKey, nb * sizeof(uint64_t));

	state[0] = nb+nk+1;

	keyExpansion_addRoundKey(k0);
	executeRound();
	keyExpansion_xorRoundKey(k1);
	executeRound();
	keyExpansion_addRoundKey(k0);
	executeRound();

    memcpy(kt, state, nb*sizeof(uint64_t));
}


void keyExpansion_addRoundKey(uint8_t* array)
{
	//pour l'addition, prendre en compte les bits de retenu => passer de byte à word
	uint64_t* tmp =(uint64_t*) array;
	uint64_t* s_64 = (uint64_t*) state;
	int i;
	for(i = 0 ; i < nb ; ++i)
	{
		s_64[i] = s_64[i] + tmp[i];
	}

	state[0] = s_64[0];
	state[sizeof(uint64_t)] = s_64[nb-1];
}



void keyExpansion_xorRoundKey(uint8_t* array)
{
	size_t i;
	for(i=0 ; i<nb*sizeof(uint64_t) ; ++i)
	{
		state[i] = state[i] ^ array[i];
	}
}


uint8_t getSboxVal(uint8_t sbox, uint8_t i)
{
	return sBoxes[sbox][i];
}


void subBytes(void)
{
	size_t i;
	size_t sbox;
	const size_t max_sboxes_number = 4;
	for(i=0 ; i<nb*sizeof(uint64_t) ; ++i)
	{
		sbox = i % max_sboxes_number;
		state[i] = getSboxVal(sbox, state[i]);
	}
}

void shiftRows(void)
{
	uint8_t tmp;
	size_t i;
	for(i=0 ; i<sizeof(uint64_t)/nb ; ++i)
	{
		tmp = state[sizeof(uint64_t)/nb+i];
		state[sizeof(uint64_t)/nb+i] = state[sizeof(uint64_t)+sizeof(uint64_t)/nb+i];
		state[sizeof(uint64_t)+sizeof(uint64_t)/nb+i] = tmp;
	}
}

uint8_t multiplyGF(uint8_t x, uint8_t y) {
    int i;
    uint8_t r = 0;
    uint8_t hbit = 0;
    for (i = 0; i < 8; ++i) {
        if ((y & 0x1) == 1)
            r ^= x;
        hbit = x & 0x80;
        x <<= 1;
        if (hbit == 0x80)
            x ^= 0x011d; // x^8 + x^4 + x^3 + x^2 + 1
        y >>= 1;
    }
    return r;
}


void mixColumns(void)
{
	uint8_t col, product, result;
	int row,b;

	uint8_t s[nb*sizeof(uint64_t)];//copie de state
	for (int i = 0; i <16 ; i++)
	{
		s[i] = state[i];
	}



	for (col=0; col<nb; ++col)
	{
		result = 0;
		for(row = 0; row < sizeof(uint64_t) ; ++row)
		{
			product = 0;
			result = 0;
			for(b = 0; b < sizeof(uint64_t) ; ++b)
			{
				product ^= multiplyGF(s[b+col*sizeof(uint64_t)], mds_matrix[row][b]);
			}
			state[row+col*sizeof(uint64_t)] = product;
		}
	}
}

void executeRound(void)
{
    subBytes();
	shiftRows();
	mixColumns();
}

void keyExpansion_even(uint8_t* kt)
{
    uint8_t initial_data [sizeof(uint64_t) * nk];
    uint8_t kt_round [sizeof(uint64_t) * nb];
    uint8_t tmv [sizeof(uint64_t) * nb];
    size_t round = 0;

    memcpy(initial_data, cipherKey, nk*sizeof(uint64_t));
    for(int i = 0; i < nb*sizeof(uint64_t) ;  i += 2)
    {
        tmv[i] = 0x01;
        tmv[i+1] = 0x00;
    }

    while(1) //Parcours des pairs
    {
        memcpy(state, kt, nb*sizeof(uint64_t));
        keyExpansion_addRoundKey(tmv);
        memcpy(kt_round, state, nb*sizeof(uint64_t));
        memcpy(state, initial_data, nb*sizeof(uint64_t));

        keyExpansion_addRoundKey(kt_round);
        executeRound();
        keyExpansion_xorRoundKey(kt_round);
        executeRound();
        keyExpansion_addRoundKey(kt_round);

        for(int j = 0 ; j< nb*sizeof(uint64_t) ; ++j)
        {
            roundKey[j+(round*nb*sizeof(uint64_t))] = state[j];
        }

        if(round == nr)
        {
            break;
        }

        round += 2;
        shiftLeft(tmv);
        rotate(initial_data);

        printf("\n");

    }
}

void shiftLeft(uint8_t* array)
{
    for(int i=0 ; i<nb*sizeof(uint64_t) ; ++i)
    {
        array[i] <<= 1;
    }
}

void rotate(uint8_t* array)
{
    uint8_t tmp;
	size_t i;
	for(i=0 ; i<sizeof(uint64_t) ; ++i)
	{
		tmp =array[i];
		array[i] = array[i+sizeof(uint64_t)];
		array[i+sizeof(uint64_t)] = tmp;
	}
}

void keyExpansion_odd(void)
{
    /* TO OPTIMIZE (no copy of array)*/
    int i,j;
    int step = nb*sizeof(uint64_t);
    uint8_t tomodify_roundKey[nb*sizeof(uint64_t)];

    for(i = 1 ; i<nr ; i+=2)//Parcours des impairs
    {
        for(j=0 ; j<nb*sizeof(uint64_t) ; ++j)
        {
            roundKey[i*step+j] = roundKey[(i*step+j)-step];
        }

        for(j=0 ; j<nb*sizeof(uint64_t) ; ++j)
        {
            tomodify_roundKey[j] = roundKey[i*step+j];
        }
        RotateLeft(tomodify_roundKey);
        for(j=0 ; j<nb*sizeof(uint64_t) ; ++j)
        {
            roundKey[i*step+j] = tomodify_roundKey[j];
        }
    }
    printf("\n");
}

void RotateLeft(uint8_t* round_key)
{
    int rotate_bytes = 2*nb+3; //7
    size_t bytes_num = nb*(64/8);//word/byte en bits

    uint8_t* buffer = (uint8_t*)malloc(rotate_bytes);

    memcpy(buffer,round_key, rotate_bytes);
    memmove(round_key, round_key+rotate_bytes, bytes_num - rotate_bytes);
    memcpy(round_key+bytes_num-rotate_bytes, buffer, rotate_bytes);

    free(buffer);

}

void displayArray(uint8_t* array)
{
	size_t i;
	for(i=0 ; i<nb*sizeof(uint64_t) ; ++i)
	{
		printf("%02x", array[i]);
	}
	printf("\n");
}

void displayRoundKey(void)
{
	size_t i;
	for(i=0 ; i<nb*sizeof(uint64_t)*(nr+1) ; ++i)
	{
	    if(i%8 == 0){printf("\n");}
		printf("%02x", roundKey[i]);
	}
	printf("\n");
}

void keyExpansion(void)
{
	/* routine that initalizes roundKey array*/
	uint8_t kt [sizeof(uint64_t) * nb];
	generateIntermediateKey(kt);
	keyExpansion_even(kt);
	keyExpansion_odd();

}

void addRoundKey(int round)
{
    uint8_t tmp_rk[16];
    for(int j=0 ; j<nb*sizeof(uint64_t) ; ++j)
        {
            tmp_rk[j] = roundKey[round*nb*sizeof(uint64_t)+j];
        }
    uint64_t* tmp =(uint64_t*) tmp_rk;
	uint64_t* s_64 = (uint64_t*) state;
	int i;
	for(i = 0 ; i < nb ; ++i)
	{
		s_64[i] = s_64[i] + tmp[i];
	}

	state[0] = s_64[0];
	state[sizeof(uint64_t)] = s_64[nb-1];
}

void xorRoundKey(int round)
{
    for(int i=0;i<nb*sizeof(uint64_t);++i)
    {
        state[i] = state[i] ^ roundKey[round*nb*sizeof(uint64_t)+i];
    }
}

void cipher(void)
{
    int round = 0;
    memcpy(state, input, nb*sizeof(uint64_t));

    addRoundKey(round);
    for(round = 1; round<nr ; ++round)
    {
        executeRound();
        xorRoundKey(round);
    }
    executeRound();
    addRoundKey(round);
}



