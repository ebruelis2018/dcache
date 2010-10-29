package org.dcache.auth;

import java.security.Principal;
import java.io.Serializable;

public class LoginUidPrincipal implements Principal, Serializable
{
    static final long serialVersionUID = 1181951214740569954L;

    private long _uid;

    public LoginUidPrincipal(long uid)
    {
        if (uid < 0) {
            throw new IllegalArgumentException("UID must be non-negative");
        }
        _uid = uid;
    }

    public LoginUidPrincipal(String uid)
    {
        this(Long.parseLong(uid));
    }

    public long getUid()
    {
        return _uid;
    }

    @Override
    public String getName()
    {
        return String.valueOf(_uid);
    }

    @Override
    public int hashCode()
    {
        return (int) _uid;
    }

    @Override
    public boolean equals(Object obj)
    {
        if (this == obj) {
            return true;
        }
        if (!(obj instanceof LoginUidPrincipal)) {
            return false;
        }
        LoginUidPrincipal other = (LoginUidPrincipal) obj;
        return (other._uid == _uid);
    }

    @Override
    public String toString() {
        return getClass().getSimpleName() + "[" + getName() + "]";
    }
}
