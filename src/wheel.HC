/* Inside this file are various functions for utility.
 * This includes String manipulation, types conversion, etc.
 * Reason why I made my own implementation is because for some
   God-forsaken reason, many of the String manipulation functions
   built-in into the language do not work. They crash.
 * I don't know if this is due to the compiler being sus or skill
   issue of mine, but alas: I've reinvented the wheel inside this file.

   - Clara
*/


// Finds first instance of chr and returns its position in src
// Returns -1 if its not found
public I64 FindChar(U8 *src, U8 chr) {
    I64 srcLen = StrLen(src);
    for (I64 i = 0; i < srcLen; i++) {
        if (src[i] == chr)
            return i;
    }

    return -1;
}

// Returns a NEW MAlloced substring of length len from the specified offset off in src.
// Returns an empty string if any errors occur
public U8 *GetSubStr(U8 *src, I64 off, I64 len) {
    if ((off + len) >= (StrLen(src) + 1))
        return StrNew("");

    return StrNCpy(src+off, len);
}

// Finds first instance of substr and returns its position in src
// Returns -1 if its not found
public I64 FindSubStr(U8 *src, U8 *substr) {
    I64 srcLen = StrLen(src);
    I64 substrLen = StrLen(substr);

    for (I64 i = 0; i <= srcLen-substrLen; i++) {
        U8 *search = GetSubStr(src, i, substrLen);
        if (!StrCmp(search, substr))
            return i;
    }

    return -1;
}

// Counts the occurrences of substr in src
public I64 CountSubStr(U8 *src, U8 *substr) {
    I64 count = -1;
    I64 location = 0;

    while (location != -1) {
        count++;
        location = FindSubStr(src+location, substr);
    }

    return count;
}

// Returns a list with the indexes of each occurence of substr in src
public IntVec *OccurencesIndexes(U8 *src, U8 *substr) {
    IntVec *occurences = IntVecNew();

    U8 *buffer = StrNew(src);
    I64 substrLen = StrLen(substr);
    I64 location = 0;
    I64 prevLen = 0;
    I64 index = 0;

    while (location != -1) {
        location = FindSubStr(buffer, substr);
        index = location;

        if (location != -1) {
            location = location + prevLen;
            IntVecPush(occurences, location);

            prevLen = location + substrLen;
            I64 offset = index + substrLen;
            I64 length = StrLen(buffer) - offset;

            buffer = GetSubStr(buffer, offset, length);
        }
    }

    Free(buffer);
    return occurences;
}

// Splits a string by a given delimiter
// Returns a PtrVec* (heap allocated)
public PtrVec *SplitStr(U8 *string, U8 *delimiter) {
    IntVec *occurences = OccurencesIndexes(string, delimiter);
    PtrVec *splitted = PtrVecNew();
    I64 delimLen = StrLen(delimiter);
    I64 offset = 0;

    for (I64 i = 0; i < occurences->size+1; i++) {
        I64 length;

        if (i < occurences->size)
            length = IntVecGet(occurences, i) - offset;

        else
            length = StrLen(string) - offset;

        U8 *buff = GetSubStr(string, offset, length);
        offset += length;
        offset += StrLen(delimiter);

        PtrVecPush(splitted, buff);
    }

    IntVecRelease(occurences);
    return splitted;
}

// Returns 1 if the given chr is a digit, 0 otherwise
public Bool IsDigit(U8 chr) {
    return (chr >= 48) && (chr <= 57);
}

// Converts a U8 character digit chr into its I32 representation
// If chr is not a digit, -1 is returned.
public I32 SCToI(U8 chr) {
    if (!IsDigit(chr))
        return -1;

    return chr - 48;
}

// Converts a U8 character digit chr into its I32 representation
// To improve performance, this function is UNCHECKED.
// If chr is not a digit, an arbitrary number will be returned. May lead to undefined behaviour.
// TODO: Change this to U64
public I32 CToI32(U8 chr) {
    return (chr - 48)(I32);
}

// Converts an ASCII  U8* nptr to an I32
// If a non-digit character is encountered, the function will stop processing.
public I32 AToI32(U8 *nptr) {
    U64 len = StrLen(nptr);
    if (len == 0)
        return 0;

    Bool isNegative = (nptr[0] == '-');
    I32 result = 0;

    for (I64 i = isNegative; i < len; i++) {
        if (!IsDigit(nptr[i]))
            i = len;

        else {
            result *= 10;
            result += CToI32(nptr[i]);
        }
    }

    if (isNegative)
        result *= -1;

    return result;
}

// Pops the element at index idx in a PtrVec* vec
// Returns 0 on error, 1 on success
public Bool PtrVecPopIdx(PtrVec *vec, I64 idx) {
    if (idx >= vec->size || idx < 0)
        return 0;

    PtrVec *temp = PtrVecNew();

    for (I64 i = vec->size-1; i > idx; i--) {
        PtrVecPush(temp, PtrVecGet(vec, i));
        PtrVecPop(vec);
    }

    for (I64 i = temp->size-2; i != 0; i++) {
        PtrVecPush(vec, PtrVecGet(temp, i));
    }

    PtrVecRelease(temp);
    return 1;
}

// Finds a substring substr in a PtrVec* vec.
// Returns the index where the substr was found.
// Returns -1 if not found.
public I64 FindSubStrInPtrVec(PtrVec *vec, U8 *substr) {
    for (I64 i = 0; i < vec->size; i++) {
        if (FindSubStr(PtrVecGet(vec, i), substr) != -1)
            return i;
    }

    return -1;
}

