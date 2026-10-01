namespace PeekMemo.Core.Settings;

public sealed class BackgroundImageException : Exception
{
    public BackgroundImageException(string message)
        : base(message)
    {
    }
}

/// Copies a chosen picture into PeekMemo's folder. The original file is left alone.
public sealed class BackgroundImageStore
{
    public BackgroundImageStore(string directory)
    {
        DirectoryPath = directory;
    }

    public string DirectoryPath { get; }

    public static bool IsSafeFilename(string? name)
    {
        if (string.IsNullOrEmpty(name) || name.Length is < 16 or >= 120)
        {
            return false;
        }

        if (!name.StartsWith("background-", StringComparison.Ordinal))
        {
            return false;
        }

        if (name.Contains('/') || name.Contains('\\') || name.Contains("..", StringComparison.Ordinal))
        {
            return false;
        }

        foreach (var character in name)
        {
            if (!char.IsAsciiLetterOrDigit(character) && character is not ('-' or '.'))
            {
                return false;
            }
        }

        return true;
    }

    public string Install(string sourcePath)
    {
        if (string.IsNullOrWhiteSpace(sourcePath) || !File.Exists(sourcePath))
        {
            throw new BackgroundImageException("The picture could not be read.");
        }

        var extension = DetectStoredExtension(sourcePath);
        if (extension is null)
        {
            throw new BackgroundImageException("The picture format is not supported.");
        }

        Directory.CreateDirectory(DirectoryPath);
        var filename = $"background-{Guid.NewGuid():N}.{extension}";
        if (!IsSafeFilename(filename))
        {
            throw new BackgroundImageException("The stored picture name was rejected.");
        }

        var destination = Path.Combine(DirectoryPath, filename);
        var fullDestination = Path.GetFullPath(destination);
        if (!IsInsideStore(fullDestination))
        {
            throw new BackgroundImageException("The stored picture name was rejected.");
        }

        if (Path.GetFullPath(sourcePath) == fullDestination)
        {
            throw new BackgroundImageException("The picture could not be copied.");
        }

        File.Copy(sourcePath, fullDestination, overwrite: false);
        return filename;
    }

    public string? ExistingFile(string? filename)
    {
        if (!IsSafeFilename(filename))
        {
            return null;
        }

        var full = Path.GetFullPath(Path.Combine(DirectoryPath, filename!));
        if (!IsInsideStore(full) || !File.Exists(full))
        {
            return null;
        }

        return full;
    }

    public bool RemoveManaged(string? filename)
    {
        var full = ExistingFile(filename);
        if (full is null)
        {
            return IsSafeFilename(filename);
        }

        File.Delete(full);
        return true;
    }

    public static string? DetectStoredExtension(string path)
    {
        var extension = Path.GetExtension(path).TrimStart('.').ToLowerInvariant();
        var header = new byte[16];
        int read;
        using (var stream = File.OpenRead(path))
        {
            read = stream.Read(header, 0, header.Length);
        }

        if (read < 3)
        {
            return null;
        }

        if (extension == "png" && header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47)
        {
            return "png";
        }

        if ((extension is "jpg" or "jpeg") && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
        {
            return "jpg";
        }

        if (extension == "bmp" && header[0] == 0x42 && header[1] == 0x4D)
        {
            return "bmp";
        }

        if (extension == "webp"
            && read >= 12
            && header[0] == (byte)'R'
            && header[1] == (byte)'I'
            && header[2] == (byte)'F'
            && header[3] == (byte)'F'
            && header[8] == (byte)'W'
            && header[9] == (byte)'E'
            && header[10] == (byte)'B'
            && header[11] == (byte)'P')
        {
            return "webp";
        }

        return null;
    }

    bool IsInsideStore(string fullPath)
    {
        var root = Path.GetFullPath(DirectoryPath);
        var prefix = root.EndsWith(Path.DirectorySeparatorChar) ? root : root + Path.DirectorySeparatorChar;
        return fullPath.StartsWith(prefix, StringComparison.Ordinal);
    }
}
