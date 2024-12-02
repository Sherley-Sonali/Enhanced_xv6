
static unsigned long seed = 1;  // Initial seed value

// Function to set the seed
void srand(unsigned long new_seed) {
    seed = new_seed;
}

// Function to generate a random number
unsigned long rand() {
    // Constants for LCG algorithm
    const unsigned long a = 1664525;
    const unsigned long c = 1013904223;
    const unsigned long m = 4294967296;  // 2^32

    seed = (a * seed + c) % m;  // Update the seed using LCG formula
    return seed;  // Return the generated random number
}

int random(){
    return rand();
}