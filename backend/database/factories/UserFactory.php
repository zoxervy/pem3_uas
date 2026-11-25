<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<User> */
class UserFactory extends Factory
{
    protected $model = User::class;

    public function definition(): array
    {
        return [
            'nama' => fake()->name(),
            'username' => fake()->unique()->userName(),
            'password' => 'password123',
            'role' => 'waitress',
            'no_hp' => null,
            'aktif' => true,
        ];
    }

    public function admin(): static { return $this->state(['role' => 'admin']); }
    public function waitress(): static { return $this->state(['role' => 'waitress']); }
    public function kasir(): static { return $this->state(['role' => 'kasir']); }
}
