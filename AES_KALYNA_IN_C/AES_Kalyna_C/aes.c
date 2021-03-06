#include "aes.h"
void keyExpansion(void)
{
	/* routine that initalizes roundKey array*/
	uint8_t* kt = generateIntermediateKey();
	keyExpansion_even(kt);

}

uint8_t* generateIntermediateKey(void)
{

	uint8_t kt [sizeof(uint64_t) * nb];
	uint8_t k1 [sizeof(uint64_t) * nb];
	uint8_t k0 [sizeof(uint64_t) * nb];

	memcpy(k0, cipherKey, nb * sizeof(uint64_t));
	memcpy(k1, cipherKey, nb * sizeof(uint64_t));

	state[0] = nb+nk+1;

	keyExpansion_addRoundKey(k0); // = .add_rkey
	executeRound();
	keyExpansion_xorRoundKey(k1);
	executeRound();
	keyExpansion_addRoundKey(k0);
	executeRound();

    memcpy(kt, state, nb*sizeof(uint64_t));
    return kt;

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

void keyExpansion_addRoundKey(uint8_t* array)
{
	/*
	size_t i;
	for(i=0 ; i<nb*sizeof(uint64_t) ; ++i)
	{
		state[i] = state[i] + array[i];
	}
	*/

	//pour l'addition, prendre en compte les bits de retenu => passer de byte à word
	uint64_t* tmp =(uint64_t*) array;
	uint64_t* s = (uint64_t*) state;
	for(int i = 0 ; i < nb ; ++i)
	{
		s[i] = s[i] + tmp[i];
	}
	state[0] = s[0];
	state[sizeof(uint64_t)] = s[nb-1];
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
    subBytes(); // = .s_box
	shiftRows(); // = .s_row
	mixColumns();// = .m_col
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
    //tmv = {0x01,0x00,0x01,0x00,0x01,0x00,0x01,0x00,0x01,0x00,0x01,0x00,0x01,0x00,0x01,0x00};

    while(1)
    {
        keyExpansion_addRoundKey(tmv);
        memcpy(kt_round, state, nb*sizeof(uint64_t));
        memcpy(state, initial_data, nb*sizeof(uint64_t));

        keyExpansion_addRoundKey(kt_round);
        executeRound();
        keyExpansion_xorRoundKey(kt_round);
        executeRound();
        printf("state  : ");displayArray(state);
        printf("kt_round  : ");displayArray(kt_round);
        keyExpansion_addRoundKey(kt_round);

        printf("state2 :");displayArray(state);




        for(int j = 0 ; j< nb*sizeof(uint64_t) ; ++j)
        {
            roundKey[j+(round*nb*sizeof(uint64_t))] = state[j];
        }


        /*
        if(round == nr)
        {
            break;
        }
        */
        break;


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

/*
void subWord(uint8_t* words)
{
	//substitute words with a sbox matrix
	words[0] = getSboxVal(words[0]);
    words[1] = getSboxVal(words[1]);
    words[2] = getSboxVal(words[2]);
    words[3] = getSboxVal(words[3]);
}

void rotWord(uint8_t* words)
{
	//single left rotation of the words array
	uint8_t tmpVal = words[0];
	words[0] = words[1];
	words[1] = words[2];
	words[2] = words[3];
	words[3] = tmpVal;
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
*/
