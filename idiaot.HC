// Finds first instance of chr and returns its position in src
// Returns -1 if its not found
public I64 FindChar(U8 *src, U8 chr)
{
    I64 srcLen = StrLen(src);
    for (I64 i = 0; i < srcLen; i++)
    {
        if (src[i] == chr)
            return i;
    }

    return -1;
}

// Returns a NEW MAlloced substring of length len from the specified offset off in src.
// Returns an empty string if any errors occur
public U8 *GetSubStr(U8 *src, I64 off, I64 len)
{
    if ((off + len) >= (StrLen(src) + 1))
        return StrNew("");

    return StrNCpy(src+off, len);
}

// Returns 1 if the given chr is a digit, 0 otherwise
public Bool IsDigit(U8 chr)
{
    return (chr >= 48) && (chr <= 57);
}

// Converts a U8 character digit chr into its I32 representation
// If chr is not a digit, -1 is returned.
public I32 SCToI(U8 chr)
{
    if (!IsDigit(chr))
        return -1;

    return chr - 48;
}

// Converts a U8 character digit chr into its I32 representation
// To improve performance, this function is UNCHECKED.
// If chr is not a digit, an arbitrary number will be returned. May lead to undefined behaviour.
public I32 CToI32(U8 chr)
{
    return chr - 48;
}

// FIX: Only works for numbers up to 3 digits
// Converts an ASCII  U8* nptr to an I32
// If a non-digit character is encountered, the function will stop processing.
public I32 AToI32(U8 *nptr)
{
    U64 len = StrLen(nptr);

    if (len == 0)
        return 0;

    Bool isNegative = (nptr[0] == '-');
    I32 result = 0;

    for (U64 i = 0; i < len; i++)
    {
        if (!IsDigit(nptr[i]))
        {
            if (isNegative)
                result *= -1;
            return result;
        }

        // HACK: For some god forsaken reason I have to delegate to a temp value.
        // Operating result directly breaks everything
        I32 temp = (result * 10) + CToI32(nptr[i]);
        result = temp;
    }

    if (isNegative)
        result *= -1;

    return result;
}

