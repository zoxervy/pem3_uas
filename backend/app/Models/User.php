<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory;

    protected $table = 'users';

    protected $fillable = ['nama', 'username', 'password', 'role', 'no_hp', 'aktif'];

    protected $hidden = ['password'];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',   // otomatis di-hash saat disimpan
            'aktif' => 'boolean',
        ];
    }

    public function isAdmin(): bool { return $this->role === 'admin'; }
    public function isWaitress(): bool { return $this->role === 'waitress'; }
    public function isKasir(): bool { return $this->role === 'kasir'; }
}
