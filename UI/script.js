// ════════════════════════════════════════════
// VARIABLES
// ════════════════════════════════════════════

let selectedGender = 'male';
let selectedNationality = '';

// ════════════════════════════════════════════
// NUI MESSAGE LISTENER (Lua → JS)
// ════════════════════════════════════════════

window.addEventListener('message', function(event) {
    const data = event.data;

    if (data.action === 'openCreator') {
        $('#creator-container').fadeIn(300);
        resetForm();
    }

    if (data.action === 'closeCreator') {
        $('#creator-container').fadeOut(300);
    }
});

// ════════════════════════════════════════════
// SLIDER TAILLE
// ════════════════════════════════════════════

const height = document.getElementById('height');
const heightValue = document.getElementById('heightValue');

height.oninput = () => {
    heightValue.textContent = height.value;
};

// ════════════════════════════════════════════
// GENRE TOGGLE
// ════════════════════════════════════════════

$('.gender-btn').click(function() {
    $('.gender-btn').removeClass('active');
    $('.gender-btn .btn-sub').text('Sélectionner');

    $(this).addClass('active');
    $(this).find('.btn-sub').text('Sélectionné');

    selectedGender = $(this).data('gender');

    // Envoyer le changement de genre au client Lua
    fetch('https://brickston_character/selectGender', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ gender: selectedGender })
    });
});

// ════════════════════════════════════════════
// DROPDOWN NATIONALITÉ
// ════════════════════════════════════════════

$('.dropdown-selected').click(function() {
    $(this).parent().toggleClass('open');
});

$('.option').click(function() {
    let text = $(this).text();
    selectedNationality = text;

    $(this)
        .closest('.dropdown')
        .find('span')
        .text(text);

    $('.dropdown').removeClass('open');
});

$(document).click(function(e) {
    if (!$(e.target).closest('.dropdown').length) {
        $('.dropdown').removeClass('open');
    }
});

// ════════════════════════════════════════════
// BOUTON CRÉER
// ════════════════════════════════════════════

$('#btn-create').click(function() {
    const firstName = $('#input-firstname').val().trim();
    const lastName = $('#input-lastname').val().trim();
    const birthDate = $('#input-birthdate').val().trim();
    const heightVal = $('#height').val();

    // Validation
    if (firstName.length < 2) {
        shakeField('#input-firstname');
        return;
    }

    if (lastName.length < 2) {
        shakeField('#input-lastname');
        return;
    }

    if (!birthDate || birthDate.length < 8) {
        shakeField('#input-birthdate');
        return;
    }

    if (!selectedNationality) {
        shakeField('#dropdown-nationality .dropdown-selected');
        return;
    }

    // Envoyer les données au client Lua
    fetch('https://brickston_character/createCharacter', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            gender: selectedGender,
            firstName: firstName,
            lastName: lastName,
            birthDate: birthDate,
            height: heightVal,
            nationality: selectedNationality
        })
    });
});

// ════════════════════════════════════════════
// BOUTON ANNULER
// ════════════════════════════════════════════

$('#btn-cancel').click(function() {
    fetch('https://brickston_character/cancelCreation', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// ════════════════════════════════════════════
// UTILS
// ════════════════════════════════════════════

function resetForm() {
    $('#input-firstname').val('');
    $('#input-lastname').val('');
    $('#input-birthdate').val('');
    $('#height').val(170);
    $('#heightValue').text('170');

    selectedGender = 'male';
    selectedNationality = '';

    $('.gender-btn').removeClass('active');
    $('.gender-btn[data-gender="male"]').addClass('active');
    $('.gender-btn[data-gender="male"] .btn-sub').text('Sélectionné');
    $('.gender-btn[data-gender="female"] .btn-sub').text('Sélectionner');

    $('#dropdown-nationality span').text('Sélectionnez une nationalité');
}

function shakeField(selector) {
    const $el = $(selector).closest('.field-box, .dropdown-selected');
    $el.addClass('shake');
    setTimeout(() => $el.removeClass('shake'), 500);
}

// Fermer avec Escape
$(document).keydown(function(e) {
    if (e.key === 'Escape') {
        fetch('https://brickston_character/cancelCreation', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});
