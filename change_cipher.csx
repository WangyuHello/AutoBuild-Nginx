#!/usr/bin/env dotnet-script

// ssl/ssl_cipher.cc
var targetFile = Args[0];
// TLS_AES_128_GCM_SHA256
// TLS_CHACHA20_POLY1305_SHA256
var targetCipher = Args[1];

int FindBegin(string[] lines, int start)
{
    for (int i = start; i > 0; i--)
    {
        if(lines[i].Trim() == "{")
        {
            return i;
        }
    }
    return -1;
}

int FindEnd(string[] lines, int start)
{
    for (int i = start; i < lines.Length; i++)
    {
        if(lines[i].Trim() == "},")
        {
            return i;
        }
    }
    return -1;
}

void CommentCipherLines(string path, string ci)
{
    var lines = File.ReadAllLines(path);
    int begin = -1;
    int end = -1;
    for(int i = 0; i < lines.Length; i++)
    {
        var l2 = lines[i].Trim();
        if(l2.Contains(ci))
        {
            begin = FindBegin(lines, i);
            end = FindEnd(lines, i);
        }
    }
    
    if(begin != -1 && end != -1)
    {
        var results = new List<string>(lines.Length);
        for(int i = 0; i < lines.Length; i++)
        {
            if(i >= begin && i <= end)
            {
                continue;
            }
            results.Add(lines[i]);
        }

        File.WriteAllLines(path, results);
    }
}

CommentCipherLines(targetFile, targetCipher);