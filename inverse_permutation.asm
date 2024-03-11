global inverse_permutation

ONLY_LEFT_BIT equ 0x80000000    ; Stała równa MAX_INT + 1 czyli 2147483648 (w U2 na 64 bitach),
                                ; czy też MIN_INT czyli -2147483648 (w U2 na 32 bitach).
ZERO equ 0x0                    ; Stała równa 0.


section .text
; Funkcja inverse_permutation odwraca w miejscu permutację zawartą w tablicy p.

; Argumenty funkcji inverse_permutation:
; rdi - wartość n (rozmiar tablicy p)
; rsi - wskaźnik na niepustą tablicę liczb całkowitych

; Wartości zwracane:
; al (fragment rax) - true, gdy wartość n była prawidłowa, a tablica p zawierała permutację liczb 0..n-1,
; false w przeciwnym przypadku
inverse_permutation:
        mov     rax, ONLY_LEFT_BIT                  ; Przechowywanie wartości INT_MAX + 1.
                                                    ; Jeśli n > INT_MAX + 1, to funkcja inverse_permutation()
                                                    ; kończy się, zwracając false, bo w tablicy p znajdują się
                                                    ;  elementy typu int, a gdy n > INT_MAX + 1, to n - 1 > INT_MAX.
        cmp     rdi, rax
        jg      .exit_false
        cmp     rdi, ZERO                           ; Tablica p ma być niepusta, więc konieczne jest, żeby n >= 0.
        jle     .exit_false

        xor     edx, edx                            ; W rejestrze edx trzymany licznik do wykorzystania w pętli.
        mov     rax, rdi                            ; Przechowanie w rejestrze rax wartości n.
        dec     rax                                 ; Po odjęciu od wartości w rejestrze rax 1, cały zapis
                                                    ; mieści się w młodszych 32 bitach.
        jmp     .loop_check_if_permutation

; Instrukcje wykonywane w przypadku stwierdzenia niepoprawności permutacji w tablicy p:
.clean_bits_and_exit:
        dec     edx                                 ; Zmniejszenie wartości indeksu rozważanego elementu tablicy.
        cmp     edx, ZERO                           ; Sprawdzenie, czy trzeba cokolwiek czyścić.
        jl      .exit_false

.loop_for_cleaning:
        mov     ecx, DWORD [rsi + 4 * rdx]          ; Znalezienie t[i]
        cmp     ecx, ZERO                           ; Znajdowanie wartości j, dla której został ustawiony
        jge     .omitting_subtraction_second        ; wcześniej najstarszy bit t[j] (równej t[i] - ONLY_LEFT_BIT, jeśli
        sub     ecx, ONLY_LEFT_BIT                  ; t[i] ma ten bit ustawiony).

.omitting_subtraction_second:
        sub     DWORD [rsi + 4 * rcx],ONLY_LEFT_BIT
        dec     edx                                 ; Zmniejszanie licznika pętli.
        cmp     edx, ZERO                           ; Sprawdzenie, czy nastąpił juz powrót do początku tablicy p.
        jge     .loop_for_cleaning                  ; Jeśli nie, to kontynuacja czyszczenia.

.exit_false:
        xor     al,al                               ; Ustawia wszystkie bity rejestru eax na 0.
        ret

; Następuje przejście po tablicy p raz, żeby w celu stwierdzenia zarówno, czy każda z liczb jest z zakresu 0..n-1,
; jak i czy nie ma powtórzeń. Opis algorytmu sprawdzania, czy ciąg zawarty w tablicy p jest permutacją liczb 0..n-1,
; jest umieszczony na końcu pliku w celu uzasadnienia, ale niezaśmiecania kodu.

.loop_check_if_permutation:
        mov     ecx, DWORD [rsi + 4 * rdx]          ; Odczytanie wartosci p[i].
        cmp     ecx, ZERO                           ; Jeśli najstarszy bit jest zapalony, następuje modyfikacja
                                                    ; zawartości rejestru ecx przez zgaszenie najstarszego bitu.
        jge     .omitting_subtraction
        sub     ecx, ONLY_LEFT_BIT
.omitting_subtraction:
        cmp     ecx, eax                            ; Sprawdzenie, czy zawartość ecx jest z zakresu 0..n-1
        jg      .clean_bits_and_exit                ; Jeśli nie, należy stwierdzić niepoprawność.
        cmp     DWORD [rsi + 4 * rcx], ZERO         ; Sprawdzenie, czy p[ecx] ma zapalony najstarszy bit.
        jl      .clean_bits_and_exit                ; Jeśli tak, należy stwierdzić niepoprawność.
        add     DWORD [rsi + 4 * rcx], ONLY_LEFT_BIT; Zaznaczenie w p[ecx], że wartość ecx wystąpiła w tablicy.
        inc     edx                                 ; Zwiększenie licznika pętli.
        cmp     rdx, rax                            ; Sprawdzenie, czy należy zakończyć pętlę.
        jle     .loop_check_if_permutation

; Sprawdzono, że ciąg liczb w tablicy p jest permutacją liczb 0..n-1.
; Odwracanie permutacji odbywa się za pomocą znajdowania cykli.

        xor     edx, edx                            ; Rejestr edx wskazuje indeks elementu w tablicy p.

.reverse:
        mov     ecx, DWORD [rsi + 4 * rdx]          ; Odczytanie wartości p[edx]
        cmp     ecx, ZERO                           ; Jeśli element o indeksie edx został już przetworzony
                                                    ; (cykl, do którego należy, został znaleziony),
                                                    ; wartość p[edx] jest nieujemna.
        jge     .next_index
        mov     r8d, edx                            ; Zapisanie w r8d indeksu pierwszego elementu cyklu - to będzie i.
        sub     ecx, ONLY_LEFT_BIT                  ; Znalezienie początkowej wartości p[i] - przed oznaczeniem jako
                                                    ; nieodwiedzony osiągniętym przez dodanie ONLY_LEFT_BIT.

.finding_cycle:
        mov     r9d, DWORD [rsi + 4 * rcx]          ; Znalezienie wartości p[p[i]].
        sub     r9d, ONLY_LEFT_BIT                  ; Pierwotna wartość - przed oznaczeniem jako nieodwiedzony.
        mov     DWORD [rsi + 4 * rcx], r8d          ; Do p[p[i]] trafia wartość i.
        mov     r8d, ecx                            ; Zmiana - nowe i jest starym p[i].
        mov     ecx, r9d                            ; Zmiana - nowe p[i] jest starym p[p[i]].
        cmp     ecx, edx                            ; Sprawdzenie, czy osiągnięty powrót do pierwszego elementu aktualnie
                                                    ; rozważanego cyklu (czy p[i] to indeks pierwszego elementu cyklu).
        jnz     .finding_cycle
        mov     DWORD [rsi + 4 * rdx], r8d

.next_index:
        inc     edx
        cmp     rdx, rax                            ; W edx zapisane, który element tablicy p jest kandydatem na pierwszy
                                                    ; element kolejnego cyklu.
        jle     .reverse

.after_reversing:
        mov     al, 0x1                             ; Nadaje rejestrowi eax wartość 1 (true).
        ret

; Uzasadnienie działania operacji z etykietą "loop_check_if_permutation".
; Jeśli w p[i] znajdę wartość j, ustawiam w p[j] najstarszy bit, w celu zaznaczenia, że j pojawiło się w permutacji.

; Idę po tablicy dla i = 0..n-1. Odczytuję p[i].
; Przypadek 1:
; Okazuje się, że p[i] jest w zakresie 0..n-1.
; Odczytuję p[p[i]]. Okazuje się, że jest ujemne. Nie wiem, czy to dlatego, że od początku było ujemne,
; czy dlatego, że jest powtórzenie. Niezależnie od przyczyny stwierdzam niepoprawność. Dla każdego j=0..i-1
; znajduję p[j] i usuwam najstarszy bit, źeby przywrócić stan tablicy z początku.

; Przypadek 2:
; Okazuje się, że p[i] jest większe równe n.
; Stwierdzam niepoprawność. Dla każdego j=0..i-1 znajduję p[j] i usuwam najstarszy bit,
; żeby przywrócić stan tablicy z początku.

; Przypadek 3:
; Okazuje się, że p[i] jest ujemne. Nie wiem, czy to dlatego, że ktoś wskazywał na i, czy dlatego, że było od początku ujemne.
; Uzasadnijmy, że w obu przypadkach jesteśmy w stanie określić przed końcem oglądania zawartości tablicy,
; czy zawartość tablicy p jest poprawną permutacją.

; Przypadek 3a:
; Załóżmy, że ktoś wskazywał na i. Jeśli mamy poprawną permutację, to już nikt inny dalej nie wskaże na i.
; A jeśli nie mamy poprawnej permutacji, to stwierdzimy to w przyszłości, bo będziemy chcieli ustawić najstarszy bit
; tam, gdzie już jest ustawiony (bo liczba ujemna lub powtórzenie), czy znajdziemy coś >= n.
; Działanie:
; Odejmuję od p[i] 0x80000000 i próbuję aktualizować p[p[i]] zgodnie z zasadami wyżej.
; (Jeśli otrzymana liczba jest >= n, to przywracam i kończę,
; a jeśli jest z zakresu 0..n-1, to aktualizuję zgodnie z zasadami wyżej, czyli kończąc w przypadku ujemnego p[p[i]]).

; Przypadek 3b:
; Załóżmy, że nikt nie wskazywał na i, tylko p[i] po prostu było ujemne od początku, ale tego nie wiemy.
; Biorę zatem p[i], odejmuję od niego 0x80000000, patrzę czy nowa liczba jest z zakresu 0..n-1
; i ustawiam najstarszy bit w p[p[i]], kończąc, jeśli jest już ustawiony.
; Załóżmy, że postępując tak, nigdy nie stwierdzimy, że ktoś wskazuje na i.
; Wtedy, z zasady szufladkowej Dirichleta (jeśli dla każdego i abs(t[i]) było z zakresu 0..n-1,
; było ich n, ale żadne z nich nie było i,
; to na jakąś inną liczbę wskażemy przynajmniej 2 razy, więc stwierdzimy niepoprawność permutacji.